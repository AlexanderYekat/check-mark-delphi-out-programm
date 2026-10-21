unit mark_validation_atol;

interface

uses
  System.SysUtils, System.Variants, Winapi.Windows, mark_validation;

type
  TMarkValidationLog = procedure(const Msg: string) of object;

  // Borrows the form's driver. Opening/closing the connection remains in the form.
  TAtolMarkValidationBackend = class(TMarkValidationBackend)
  private
    FDriver: OleVariant;
    FLog: TMarkValidationLog;
    function CaptureError(CommandResult: Integer; const Operation: string): TMarkValidationError;
    function HasTag(const Tags: string; Tag: Integer): Boolean;
  public
    constructor Create(const Driver: OleVariant; LogProc: TMarkValidationLog);
    function BeginCheck(const Mark: string; PlannedStatus: Integer): TMarkValidationError; override;
    function PollCheck(out Ready: Boolean): TMarkValidationError; override;
    function ReadResult: TMarkValidationData; override;
    function AcceptCheck: TMarkValidationError; override;
    function ReadAcceptedValidationResult: Integer; override;
    function CancelCheck: TMarkValidationError; override;
    function DeclineCheck: TMarkValidationError; override;
    function TickMs: UInt64; override;
    procedure SleepMs(Milliseconds: Cardinal); override;
    procedure Log(const Msg: string); override;
  end;

implementation

constructor TAtolMarkValidationBackend.Create(const Driver: OleVariant; LogProc: TMarkValidationLog);
begin
  inherited Create;
  FDriver := Driver;
  FLog := LogProc;
end;

function TAtolMarkValidationBackend.CaptureError(CommandResult: Integer;
  const Operation: string): TMarkValidationError;
begin
  // Read both immediately: a subsequent driver command overwrites its error state.
  Result.Code := FDriver.errorCode;
  Result.Description := FDriver.errorDescription;
  if (CommandResult <> 0) and (Result.Code = 0) then
  begin
    Result.Code := -1;
    Result.Description := Operation + ' returned ' + IntToStr(CommandResult) +
      ' without a driver error code. ' + Result.Description;
  end;
end;

function TAtolMarkValidationBackend.HasTag(const Tags: string; Tag: Integer): Boolean;
begin
  Result := Pos(';' + IntToStr(Tag) + ';', ';' + Tags + ';') > 0;
end;

function TAtolMarkValidationBackend.BeginCheck(const Mark: string;
  PlannedStatus: Integer): TMarkValidationError;
var
  CommandResult: Integer;
begin
  // Reapply all parameters on every attempt; never reuse a previous mark's outputs.
  FDriver.setParam(FDriver.LIBFPTR_PARAM_MARKING_CODE_TYPE, FDriver.LIBFPTR_MCT12_AUTO);
  FDriver.setParam(FDriver.LIBFPTR_PARAM_MARKING_CODE, Mark);
  FDriver.setParam(FDriver.LIBFPTR_PARAM_MARKING_CODE_STATUS, PlannedStatus);
  FDriver.setParam(FDriver.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);
  CommandResult := FDriver.beginMarkingCodeValidation;
  Result := CaptureError(CommandResult, 'beginMarkingCodeValidation');
end;

function TAtolMarkValidationBackend.PollCheck(out Ready: Boolean): TMarkValidationError;
var
  CommandResult: Integer;
begin
  Ready := False;
  CommandResult := FDriver.getMarkingCodeValidationStatus;
  Result := CaptureError(CommandResult, 'getMarkingCodeValidationStatus');
  if Result.Code = 0 then
    Ready := FDriver.getParamBool(FDriver.LIBFPTR_PARAM_MARKING_CODE_VALIDATION_READY);
end;

function TAtolMarkValidationBackend.ReadResult: TMarkValidationData;
var
  Tags: string;
begin
  Result := Default(TMarkValidationData);
  Result.RequestSent := FDriver.getParamBool(FDriver.LIBFPTR_PARAM_IS_REQUEST_SENT);
  Result.OnlineError.Code := FDriver.getParamInt(FDriver.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_ERROR);
  if Result.OnlineError.Code <> 0 then
  begin
    Result.OnlineError.Description := FDriver.getParamString(
      FDriver.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_ERROR_DESCRIPTION);
    // According to the SDK the remaining result fields are not valid in this case.
    Exit;
  end;

  Result.ValidationResult := FDriver.getParamInt(FDriver.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT);
  Tags := FDriver.getParamString(FDriver.LIBFPTR_PARAM_TLV_LIST);
  Result.HasProcessingCode := HasTag(Tags, 2105);
  if Result.HasProcessingCode then
    Result.ProcessingCode := FDriver.getParamInt(2105);
  Result.HasResponseInfo := HasTag(Tags, 2109);
  if Result.HasResponseInfo then
    Result.ResponseInfo := FDriver.getParamInt(2109);
end;

function TAtolMarkValidationBackend.AcceptCheck: TMarkValidationError;
var
  CommandResult: Integer;
begin
  CommandResult := FDriver.acceptMarkingCode;
  Result := CaptureError(CommandResult, 'acceptMarkingCode');
end;

function TAtolMarkValidationBackend.ReadAcceptedValidationResult: Integer;
begin
  // Accept produces the final tag 2106 value stored by the fiscal drive.
  Result := FDriver.getParamInt(FDriver.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT);
end;

function TAtolMarkValidationBackend.CancelCheck: TMarkValidationError;
var
  CommandResult: Integer;
begin
  CommandResult := FDriver.cancelMarkingCodeValidation;
  Result := CaptureError(CommandResult, 'cancelMarkingCodeValidation');
end;

function TAtolMarkValidationBackend.DeclineCheck: TMarkValidationError;
var
  CommandResult: Integer;
begin
  CommandResult := FDriver.declineMarkingCode;
  Result := CaptureError(CommandResult, 'declineMarkingCode');
end;

function TAtolMarkValidationBackend.TickMs: UInt64;
begin
  Result := GetTickCount64;
end;

procedure TAtolMarkValidationBackend.SleepMs(Milliseconds: Cardinal);
begin
  // No ProcessMessages: a timer must not re-enter the marking procedure.
  Sleep(Milliseconds);
end;

procedure TAtolMarkValidationBackend.Log(const Msg: string);
begin
  if Assigned(FLog) then
    FLog(Msg);
end;

end.
