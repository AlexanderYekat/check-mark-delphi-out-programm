unit mark_validation;

{$IFDEF FPC}
{$MODE DELPHI}
{$H+}
{$ENDIF}

interface

type
  TMarkValidationError = record
    Code: Integer;
    Description: string;
  end;

  TMarkValidationData = record
    ValidationResult: Integer;
    RequestSent: Boolean;
    HasProcessingCode: Boolean;
    ProcessingCode: Integer;
    HasResponseInfo: Boolean;
    ResponseInfo: Integer;
    OnlineError: TMarkValidationError;
  end;

  TMarkValidationResult = record
    Error: TMarkValidationError;
    // Non-blocking online error: the mark was still accepted.
    Warning: TMarkValidationError;
    Data: TMarkValidationData;
    Accepted: Boolean;
    Attempts: Integer;
    CleanupSucceeded: Boolean;
  end;

  // Implementations must capture each command's return/error immediately.
  // TickMs is monotonic. SleepMs and Log must not pump UI messages.
  TMarkValidationBackend = class abstract
  public
    function BeginCheck(const Mark: string; PlannedStatus: Integer): TMarkValidationError; virtual; abstract;
    function PollCheck(out Ready: Boolean): TMarkValidationError; virtual; abstract;
    function ReadResult: TMarkValidationData; virtual; abstract;
    function AcceptCheck: TMarkValidationError; virtual; abstract;
    function ReadAcceptedValidationResult: Integer; virtual; abstract;
    function CancelCheck: TMarkValidationError; virtual; abstract;
    function DeclineCheck: TMarkValidationError; virtual; abstract;
    function TickMs: UInt64; virtual; abstract;
    procedure SleepMs(Milliseconds: Cardinal); virtual; abstract;
    procedure Log(const Msg: string); virtual; abstract;
  end;

function ValidateMark(Backend: TMarkValidationBackend; const Mark: string;
  PlannedStatus: Integer): TMarkValidationResult;

implementation

uses
  SysUtils;

const
  MAX_ATTEMPTS = 3;
  WAIT_TIMEOUT_MS = 60000;
  POLL_INTERVAL_MS = 300;
  ERROR_EXCEPTION = -1;
  ERROR_TIMEOUT = 601;
  ERROR_PROCESSING = 602;
  ERROR_RESPONSE = 603;
  // LIBFPTR_ERROR_MARK_CHECK_TIMEOUT_EXPIRED: the server did not answer in time.
  ONLINE_ERROR_CHECK_TIMEOUT = 421;

type
  TCleanupKind = (ckCancel, ckDecline);

function MakeError(Code: Integer; const Description: string): TMarkValidationError;
begin
  Result.Code := Code;
  Result.Description := Description;
end;

function IsRetryable(Code: Integer): Boolean;
begin
  Result := (Code = 401) or (Code = 403) or (Code = 407) or (Code = 410);
end;

function Cleanup(Backend: TMarkValidationBackend;
  Kind: TCleanupKind; out RaisedException: Boolean): TMarkValidationError;
begin
  RaisedException := False;
  try
    if Kind = ckDecline then
      Result := Backend.DeclineCheck
    else
      Result := Backend.CancelCheck;
  except
    on E: Exception do
    begin
      RaisedException := True;
      Result := MakeError(ERROR_EXCEPTION, E.ClassName + ': ' + E.Message);
    end;
  end;
end;

function ValidateMark(Backend: TMarkValidationBackend; const Mark: string;
  PlannedStatus: Integer): TMarkValidationResult;
var
  Attempt: Integer;
  Ready, NeedsCleanup, AcceptCalled, CanRetry, CleanupRaisedException: Boolean;
  StartedAt, Elapsed: UInt64;
  DelayMs: Cardinal;
  CleanupKind: TCleanupKind;
  CleanupError: TMarkValidationError;
  Stage, CleanupName: string;
begin
  Result := Default(TMarkValidationResult);
  Result.CleanupSucceeded := True;
  if Backend = nil then
  begin
    Result.Error := MakeError(ERROR_EXCEPTION, 'Mark validation backend is not assigned');
    Exit;
  end;

  for Attempt := 1 to MAX_ATTEMPTS do
  begin
    Result.Attempts := Attempt;
    Result.Data := Default(TMarkValidationData);
    Result.Warning := Default(TMarkValidationError);
    Ready := False;
    NeedsCleanup := False;
    AcceptCalled := False;
    CanRetry := False;
    CleanupKind := ckCancel;
    Stage := 'logging attempt';

    try
      Backend.Log(Format('Mark validation attempt %d/%d', [Attempt, MAX_ATTEMPTS]));
      Stage := 'begin';
      // If begin throws, attempt cancellation. A returned error below selects
      // the same cleanup path as the source algorithm.
      NeedsCleanup := True;
      Result.Error := Backend.BeginCheck(Mark, PlannedStatus);
      if Result.Error.Code <> 0 then
      begin
        // Match the source algorithm: only 401 cancels a failed begin.
        // In particular, 407 goes straight to the delay and same-mark retry.
        NeedsCleanup := Result.Error.Code = 401;
        CanRetry := IsRetryable(Result.Error.Code);
      end
      else
      begin
        Stage := 'waiting for validation';
        StartedAt := Backend.TickMs;
        while True do
        begin
          if Backend.TickMs - StartedAt >= WAIT_TIMEOUT_MS then
          begin
            Result.Error := MakeError(ERROR_TIMEOUT, 'Mark validation timed out after 60000 ms');
            Break;
          end;

          Ready := False;
          Result.Error := Backend.PollCheck(Ready);
          if Result.Error.Code <> 0 then
          begin
            CanRetry := IsRetryable(Result.Error.Code);
            Break;
          end;

          // A backend call may itself take time; do not accept a late result.
          Elapsed := Backend.TickMs - StartedAt;
          if Elapsed >= WAIT_TIMEOUT_MS then
          begin
            Result.Error := MakeError(ERROR_TIMEOUT, 'Mark validation timed out after 60000 ms');
            Break;
          end;
          if Ready then
            Break;

          DelayMs := POLL_INTERVAL_MS;
          if WAIT_TIMEOUT_MS - Elapsed < DelayMs then
            DelayMs := Cardinal(WAIT_TIMEOUT_MS - Elapsed);
          Backend.SleepMs(DelayMs);
        end;

        if (Result.Error.Code = 0) and Ready then
        begin
          Stage := 'reading validation result';
          Result.Data := Backend.ReadResult;
          Backend.Log(Format('ValidationResult=%d; RequestSent=%s; HasProcessingCode=%s; ProcessingCode=%d; HasResponseInfo=%s; ResponseInfo=%d',
            [Result.Data.ValidationResult, BoolToStr(Result.Data.RequestSent, True),
             BoolToStr(Result.Data.HasProcessingCode, True), Result.Data.ProcessingCode,
             BoolToStr(Result.Data.HasResponseInfo, True), Result.Data.ResponseInfo]));

          if (Result.Data.OnlineError.Code <> 0) and
            (Result.Data.OnlineError.Code <> ONLINE_ERROR_CHECK_TIMEOUT) then
            Result.Error := Result.Data.OnlineError
          else if Result.Data.HasProcessingCode and (Result.Data.ProcessingCode <> 0) then
          begin
            Result.Error := MakeError(ERROR_PROCESSING,
              Format('Mark validation rejected: processingCode (2105) = %d', [Result.Data.ProcessingCode]));
            CleanupKind := ckDecline;
          end
          else if Result.Data.HasResponseInfo and
            ((Result.Data.ResponseInfo = 2) or (Result.Data.ResponseInfo = 3)) then
          begin
            Result.Error := MakeError(ERROR_RESPONSE,
              Format('Mark validation rejected: responseInfo (2109) = %d', [Result.Data.ResponseInfo]));
            CleanupKind := ckDecline;
          end
          else
          begin
            if Result.Data.OnlineError.Code = ONLINE_ERROR_CHECK_TIMEOUT then
            begin
              // As in the source 1C algorithm, a server timeout does not block
              // the sale: accept the mark with the fiscal drive's local check.
              Result.Warning := Result.Data.OnlineError;
              Backend.Log(Format('WARNING: online validation error %d (%s); accepting without server response',
                [Result.Warning.Code, Result.Warning.Description]));
            end;
            if not Result.Data.HasProcessingCode then
              Backend.Log('WARNING: processingCode (2105) is not available');
            if not Result.Data.HasResponseInfo then
              Backend.Log('WARNING: responseInfo (2109) is not available');
            if not Result.Data.RequestSent then
              Backend.Log('WARNING: IS_REQUEST_SENT=false; accepting with the original validation result');

            Stage := 'accept';
            // From this point, neither retry nor automatic cleanup is safe:
            // accept can succeed at the device even if its response is lost.
            AcceptCalled := True;
            NeedsCleanup := False;
            Result.Error := Backend.AcceptCheck;
            if Result.Error.Code = 0 then
            begin
              Result.Accepted := True;
              Result.CleanupSucceeded := True;
              Stage := 'reading accepted validation result';
              Result.Data.ValidationResult := Backend.ReadAcceptedValidationResult;
            end
            else
              Result.CleanupSucceeded := False;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        Result.Error := MakeError(ERROR_EXCEPTION,
          'Exception during ' + Stage + ': ' + E.ClassName + ': ' + E.Message);
        CanRetry := False;
        if AcceptCalled and not Result.Accepted then
          Result.CleanupSucceeded := False;
      end;
    end;

    if NeedsCleanup and (Result.Error.Code <> 0) then
    begin
      CleanupError := Cleanup(Backend, CleanupKind, CleanupRaisedException);
      Result.CleanupSucceeded := CleanupError.Code = 0;
      if CleanupRaisedException then
        CanRetry := False;
      if CleanupError.Code <> 0 then
      begin
        if CleanupKind = ckDecline then
          CleanupName := 'decline'
        else
          CleanupName := 'cancel';
        // Keep the primary error code and add the secondary failure.
        Result.Error.Description := Result.Error.Description +
          Format(' | Cleanup %s failed [%d]: %s',
            [CleanupName, CleanupError.Code, CleanupError.Description]);
      end;
    end;

    if (Result.Error.Code = 0) or AcceptCalled or Result.Accepted or
      not CanRetry or (Attempt = MAX_ATTEMPTS) then
      Exit;

    // A returned cancel error must not suppress the source algorithm's retry.
    // Keep its diagnostics, but retry using the original validation error code.
    if Result.Error.Code = 401 then
      DelayMs := 5000
    else
      DelayMs := 10000;
    try
      Backend.Log(Format('Mark validation attempt %d failed [%d]: %s',
        [Attempt, Result.Error.Code, Result.Error.Description]));
      Backend.Log(Format('Retry after error %d in %d ms', [Result.Error.Code, DelayMs]));
      Backend.SleepMs(DelayMs);
    except
      on E: Exception do
      begin
        // Keep the last known cleanup state if waiting/logging fails.
        Result.Error := MakeError(ERROR_EXCEPTION,
          'Exception before retry: ' + E.ClassName + ': ' + E.Message);
        Exit;
      end;
    end;
  end;
end;

end.
