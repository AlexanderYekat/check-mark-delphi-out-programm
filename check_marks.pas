unit check_marks;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ComObj, System.JSON;

const
  DRIVER_NOT_INIT = 'не инициализирован';
  TEXT_SHIFT_OPENNED = 'открыта';
  TEXT_SHIFT_CLOSED = 'закрыта';
  TEXT_SHIFT_EXPIRED = 'истекла';

  RESULT_COMMAND_OK = 'OK';
  TYPE_OF_CHECK_SELL = 'sell';
  TYPE_OF_CHECK_RETURN = 'return';

  PLANNED_STATUS_OF_MARK_PIECE_SOLD = 'штучный товар, реализован';
  PLANNED_STATUS_OF_MARK_DRY_FOR_SALE = 'мерный товар, в стадии реализации';
  PLANNED_STATUS_OF_PIECE_RETURN = 'штучный товар, возвращен';
  PLANNED_STATUS_OF_DRY_RETURN = 'штучный товар, в стадии реализации';
  PLANNED_STATUS_OF_PIECE_FOR_SALE = 'штучный товар, в стадии реализации';
  PLANNED_STATUS_OF_DRY_SOLD = 'мерный товар, реализован';
  PLANNED_STATUS_OF_UNCHANGED = 'статус товара не изменился';

type
  TCheckMarksForm = class(TForm)
    MemoMarks: TMemo;
    EditSellOrReturn: TEdit;
    ButtonCheckMarksOnKKT: TButton;
    MemoJSONResultCheckOnKKT: TMemo;
    ResultCodeCheckOnKKTEdit: TEdit;
    ResultDescrCheckOnKKTEdit: TEdit;
    CreateDriverKKTButton: TButton;
    CheckMarkOnKKTButton: TButton;
    EditMark: TEdit;
    ButtonGetTasks: TButton;
    MemoTasks: TMemo;
    MemoCurrentTask: TMemo;
    ButtonCheckStatusKKT: TButton;
    MemoResultJSONTask: TMemo;
    EditCodeResultOfTask: TEdit;
    EditDescrResultOfTask: TEdit;
    ButtonSaveResultTask: TButton;
    EditSeesionOfTasks: TEdit;
    MemoAllMarksOfSession: TMemo;
    ButtonCheckPermitMark: TButton;
    EditCodeResultCheckPermit: TEdit;
    EditDescrResultPerimtCheck: TEdit;
    MemoJSONResultCheckPermit: TMemo;
    ButtonCheckPermitMarks: TButton;
    ButtonCheckMark: TButton;
    ButtonCheckMArks: TButton;
    ButtonFromResultCheckToResultOfTask: TButton;
    EditCurrentIDOfTask: TEdit;
    LabelCurrentIdOfTask: TLabel;
    ButtonRemoveTask: TButton;
    ButtonGetNextTask: TButton;
    ButtonCreateNewSession: TButton;
    ButtonFinishSession: TButton;
    ButtonOpenShiftIfNeed: TButton;
    ButtonDissconnectFromKKT: TButton;
    ButtonConnectToKKT: TButton;
    ButtonDestroyDriver: TButton;
    LabelCaptionOfStatusShift: TLabel;
    LabelStatusOfShift: TLabel;
    LabelInitDriverKKT: TLabel;
    LabelConnectionWithKKT: TLabel;
    CheckBoxEmulationKKT: TCheckBox;
    LabelResultCommandDescr: TLabel;
    LabelResultCommandCode: TLabel;
    LabelCaptionResultCommans: TLabel;
    EditCassierName: TEdit;
    ComboBoxPlannedStatusOfMark: TComboBox;
    ComboBoxCheckType: TComboBox;
    ComboBoxTimeZone: TComboBox;
    procedure CreateDriverKKTButtonClick(Sender: TObject);
    procedure ButtonDestroyDriverClick(Sender: TObject);
    procedure ButtonConnectToKKTClick(Sender: TObject);
    procedure ButtonDissconnectFromKKTClick(Sender: TObject);
    procedure ButtonCheckStatusKKTClick(Sender: TObject);
    procedure ButtonOpenShiftIfNeedClick(Sender: TObject);
    procedure CheckMarkOnKKTButtonClick(Sender: TObject);
  private
    { Private declarations }
    fptr: OLEVariant;
    function CreateJSONAcceptOrDeclineOrCancel(ActionType: string): string;
    function RunProcessOnKKT(JSONRequest: string; var JSONResponse: string; var ErrorCode: Integer; var ErrorDescr: string): Boolean;
  public
    { Public declarations }
  end;

var
  CheckMarksForm: TCheckMarksForm;

implementation

{$R *.dfm}

// Выполнение команды на ККТ через JSON (аналог функции 1С ВыполнитьЗаданиеJSON)
function TCheckMarksForm.RunProcessOnKKT(JSONRequest: string; var JSONResponse: string; var ErrorCode: Integer; var ErrorDescr: string): Boolean;
var
  ResultValidate: Integer;
  ResultProcess: Integer;
  timeZoneInt:integer;
begin
  Result := False;
  ErrorCode := 0;
  ErrorDescr := '';
  JSONResponse := '';

  timeZoneInt:=ComboBoxTimeZone.ItemIndex + 1;

  try
    // Проверяем корректность JSON (аналог validateJson в 1С)
    //fptr.setParam(fptr.LIBFPTR_PARAM_JSON_DATA, JSONRequest);
    //ResultValidate := fptr.validateJson;

    //if ResultValidate <> 0 then
    //begin
    //  ErrorCode := fptr.errorCode;
    //  ErrorDescr := fptr.errorDescription;
    //  Exit;
    //end;

    // Устанавливаем временную зону (как в 1С)
    fptr.setSingleSetting(fptr.LIBFPTR_SETTING_TIME_ZONE, timeZoneInt);
    fptr.applySingleSettings;

    // Выполняем JSON команду на ККТ (аналог processJson в 1С)
    fptr.setParam(fptr.LIBFPTR_PARAM_JSON_DATA, JSONRequest);
    ResultProcess := fptr.processJson;

    if (ResultProcess <> 0) then
    begin
      ErrorCode := fptr.errorCode;
      ErrorDescr := fptr.errorDescription;
      LabelResultCommandDescr.Caption:=ErrorDescr;
      if not(CheckBoxEmulationKKT.Checked) then Exit;
    end;

    LabelResultCommandDescr.Caption:=ErrorDescr;
    // Получаем JSON ответ от драйвера
    JSONResponse := fptr.getParamString(fptr.LIBFPTR_PARAM_JSON_DATA);
    // Режим эмуляции - возвращаем тестовый ответ в формате реального ответа от ККТ
    if CheckBoxEmulationKKT.Checked then begin
      JSONResponse := '{"itemInfoCheckResult": {' +
                      '"ecrStandAloneFlag": false,' +
                      '"imcCheckFlag": true,' +
                      '"imcCheckResult": true,' +
                      '"imcEstimatedStatusCorrect": true,' +
                      '"imcStatusInfo": true' +
                      '}}';
    end;
    ErrorCode:=0;
    ErrorDescr := RESULT_COMMAND_OK;
    Result := True;
  except
    on E: Exception do
    begin
      ErrorDescr := 'Исключение при выполнении команды: ' + E.Message;
      ErrorCode := -1;
      Result := False;
    end;
  end;
end;

procedure TCheckMarksForm.CheckMarkOnKKTButtonClick(Sender: TObject);
var
    mark: String;
    validationResult: Integer;
    statusPlannedOfMark: integer;
    jsonOut: string;
    jsonAnswer: string;
    errorCode: Integer;
    errorDescr: string;
    actionType: string;
    success: Boolean;
begin
    // Очищаем результаты предыдущей проверки
    MemoJSONResultCheckOnKKT.Clear;
    ResultCodeCheckOnKKTEdit.Text := '0';
    ResultDescrCheckOnKKTEdit.Text := RESULT_COMMAND_OK;
    
    statusPlannedOfMark:=fptr.LIBFPTR_MES_PIECE_SOLD;
    if ComboBoxCheckType.ItemIndex = 1 then begin
      statusPlannedOfMark:=fptr.LIBFPTR_MES_PIECE_RETURN;
    end;
    if (ComboBoxCheckType.ItemIndex <> 0) and (ComboBoxCheckType.ItemIndex <> 2) then begin
      if ComboBoxCheckType.ItemIndex = 1 then statusPlannedOfMark:=fptr.LIBFPTR_MES_DRY_FOR_SALE;
      if ComboBoxCheckType.ItemIndex = 3 then statusPlannedOfMark:=fptr.LIBFPTR_MES_DRY_RETURN;
      if ComboBoxCheckType.ItemIndex = 4 then statusPlannedOfMark:=fptr.LIBFPTR_MES_PIECE_FOR_SALE;
      if ComboBoxCheckType.ItemIndex = 5 then statusPlannedOfMark:=fptr.LIBFPTR_MES_DRY_SOLD;
      if ComboBoxCheckType.ItemIndex = 6 then statusPlannedOfMark:=fptr.LIBFPTR_MES_UNCHANGED;
    end;

    //mark := '014494550435306821QXYXSALGLMYQQ' + #29 + '91EE06' + #29 + '92YWCXbmK6SN8vvwoxZFk7WAY8WoJNMGGr6Cgtiuja04c=';
    mark:=StringReplace(EditMark.Text, '\u001d', #29, [rfReplaceAll, rfIgnoreCase]);
    // Запускаем проверку КМ в синхронном режиме с таймаутом 2 минуты (120000 миллисекунд)
    fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_CODE_TYPE, fptr.LIBFPTR_MCT12_AUTO);
    fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_CODE, mark);
    fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_CODE_STATUS, statusPlannedOfMark);
    //fptr.setParam(fptr.LIBFPTR_PARAM_QUANTITY, 1.000);
    //fptr.setParam(fptr.LIBFPTR_PARAM_MEASUREMENT_UNIT, fptr.LIBFPTR_IU_PIECE);
    fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);
    //fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_FRACTIONAL_QUANTprocedure TCheckMarksForm.ButtonCheckPermitMarkClick(Sender: TObject);

    //fptr.setParam(fptr.LIBFPTR_PARAM_TIMEOUT, 120000);
    fptr.beginMarkingCodeValidation;

    // Выполнение данного потока останавливается до тех пор, пока не будет выполнена проверка КМ!
    ErrorCode := fptr.errorCode;
    if ErrorCode = 401 then begin //процедура проверки марки уже была запущена
      actionType := 'cancelMarkingCodeValidation';
      jsonOut := CreateJSONAcceptOrDeclineOrCancel(actionType);
      success := RunProcessOnKKT(jsonOut, jsonAnswer, errorCode, errorDescr);

      fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_CODE_TYPE, fptr.LIBFPTR_MCT12_AUTO);
      fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_CODE, mark);
      fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_CODE_STATUS, statusPlannedOfMark);
      //fptr.setParam(fptr.LIBFPTR_PARAM_QUANTITY, 1.000);
      //fptr.setParam(fptr.LIBFPTR_PARAM_MEASUREMENT_UNIT, fptr.LIBFPTR_IU_PIECE);
      fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_PROCESSING_MODE, 0);
      //fptr.setParam(fptr.LIBFPTR_PARAM_MARKING_FRACTIONAL_QUANTITY, '1/2');
      //fptr.setParam(fptr.LIBFPTR_PARAM_TIMEOUT, 120000);
      fptr.beginMarkingCodeValidation;
      ErrorCode := fptr.errorCode;
    end;


    if (ErrorCode <> 0) and not (CheckBoxEmulationKKT.Checked) then begin
      errorDescr:=fptr.errorDescription;
      ResultCodeCheckOnKKTEdit.Text:=IntToStr(ErrorCode);
      ResultDescrCheckOnKKTEdit.Text:=errorDescr;
      exit;
    end;

    fptr.getMarkingCodeValidationStatus;
    if not fptr.getParamBool(fptr.LIBFPTR_PARAM_MARKING_CODE_VALIDATION_READY) and not (CheckBoxEmulationKKT.Checked) then
    begin
      errorDescr:=fptr.errorDescription;
      ResultCodeCheckOnKKTEdit.Text:=IntToStr(ErrorCode);
      ResultDescrCheckOnKKTEdit.Text:=errorDescr;
      exit;
    end;
    //validationResult := fptr.getParamInt(fptr.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT);
    //fptr.getParamInt(fptr.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT);

    // Определяем тип действия: принять или отклонить марку
    // validationResult = 1 - марка валидна, принимаем
    // validationResult <> 1 - марка невалидна, отклоняем
    //if validationResult = 1 then
    actionType := 'acceptMarkingCode';
    //else
    //  actionType := 'declineMarkingCode';
    
    // Формируем JSON запрос
    jsonOut := CreateJSONAcceptOrDeclineOrCancel(actionType);
    //MemoJSONResultCheckOnKKT.Lines.Add('JSON запрос: ' + jsonOut);

    // Выполняем команду на ККТ через JSON
    success := RunProcessOnKKT(jsonOut, jsonAnswer, errorCode, errorDescr);

    // Отображаем результаты
    //MemoJSONResultCheckOnKKT.Lines.Add('JSON ответ: ' + jsonAnswer);
    MemoJSONResultCheckOnKKT.Lines.Add(jsonAnswer);
    ResultCodeCheckOnKKTEdit.Text := IntToStr(errorCode);
    ResultDescrCheckOnKKTEdit.Text := errorDescr;
    
    // Парсим и отображаем детали ответа
    //ParseAndDisplayJSONResponse(jsonAnswer);

    if success then
      MemoJSONResultCheckOnKKT.Lines.Add('Команда выполнена успешно')
    else
      MemoJSONResultCheckOnKKT.Lines.Add('Ошибка выполнения команды');
end;

procedure TCheckMarksForm.CreateDriverKKTButtonClick(Sender: TObject);
var
 version:string;
begin
  version:='';
  if LabelInitDriverKKT.Caption <> DRIVER_NOT_INIT then begin
    exit;
  end;
  try
    fptr := CreateOleObject('AddIn.Fptr10');
  except
    LabelInitDriverKKT.Caption:='ошибка инициализации драйвекра Атол';
    exit;
  end;
  version:=fptr.version;
  LabelInitDriverKKT.Caption:=version;
end;

procedure TCheckMarksForm.ButtonCheckStatusKKTClick(Sender: TObject);
var
    state:      Longint;
    number:     Longint;
    dateTime:   TDateTime;
begin
    fptr.setParam(fptr.LIBFPTR_PARAM_DATA_TYPE, fptr.LIBFPTR_DT_SHIFT_STATE);
    fptr.queryData;

    state       := fptr.getParamInt(fptr.LIBFPTR_PARAM_SHIFT_STATE);
    if state = fptr.LIBFPTR_SS_OPENED then LabelStatusOfShift.Caption:=TEXT_SHIFT_OPENNED;
    if state = fptr.LIBFPTR_SS_CLOSED then LabelStatusOfShift.Caption:=TEXT_SHIFT_CLOSED;
    if state = fptr.LIBFPTR_SS_EXPIRED then LabelStatusOfShift.Caption:=TEXT_SHIFT_EXPIRED;

    if CheckBoxEmulationKKT.Checked then LabelStatusOfShift.Caption:=TEXT_SHIFT_OPENNED
end;

procedure TCheckMarksForm.ButtonConnectToKKTClick(Sender: TObject);
var
  isOpened :boolean;
  textOfConnection:string;
begin
  isOpened := fptr.isOpened;
  if isOpened then
    textOfConnection:='connected'
  else begin
    fptr.open;
    isOpened := fptr.isOpened;
  end;
  if CheckBoxEmulationKKT.Checked then begin
    isOpened:=true;
    textOfConnection:='connected - эмуляция ККТ';
  end;
  if not(isOpened) then
    textOfConnection:=fptr.errorDescription;
  if CheckBoxEmulationKKT.Checked then

  LabelConnectionWithKKT.Caption:=textOfConnection;
end;

procedure TCheckMarksForm.ButtonOpenShiftIfNeedClick(Sender: TObject);
var
  Cassier:string;
  errorCode:integer;
begin
  LabelResultCommandCode.Caption:='0';
  LabelResultCommandDescr.Caption:=RESULT_COMMAND_OK;
  if LabelStatusOfShift.Caption <> TEXT_SHIFT_CLOSED then exit;

  Cassier:=EditCassierName.Text;
  fptr.setParam(1021, Cassier);
  //fptr.setParam(1203, '123456789047');
  fptr.operatorLogin;

  fptr.openShift;
  //fptr.checkDocumentClosed;

  LabelResultCommandDescr.Caption:=RESULT_COMMAND_OK;
  errorCode:=fptr.errorCode;
  if errorCode <> 0 then begin
    LabelResultCommandCode.Caption:=IntToStr(errorCode);
    LabelResultCommandDescr.Caption:=fptr.errorDescription;
  end;
end;

procedure TCheckMarksForm.ButtonDissconnectFromKKTClick(Sender: TObject);
begin
  fptr.close;
  LabelConnectionWithKKT.Caption:='disconnected';
end;

procedure TCheckMarksForm.ButtonDestroyDriverClick(Sender: TObject);
begin
  fptr := Unassigned;
  LabelInitDriverKKT.Caption:='не инициализирован';
end;

// Формирование JSON запроса для принятия/отклонения/отмены марки
function TCheckMarksForm.CreateJSONAcceptOrDeclineOrCancel(ActionType: string): string;
var
  JSONObj: TJSONObject;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.AddPair('type', ActionType);
    Result := JSONObj.ToString;
  finally
    JSONObj.Free;
  end;
end;

end.
