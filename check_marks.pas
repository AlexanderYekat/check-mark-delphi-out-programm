unit check_marks;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ComObj, System.JSON, System.IOUtils, System.NetEncoding,
  Vcl.ExtCtrls, System.Net.HttpClient, System.Net.URLClient, System.DateUtils;

const
  DRIVER_NOT_INIT = 'не инициализирован';
  TEXT_SHIFT_OPENNED = 'открыта';
  TEXT_SHIFT_CLOSED = 'закрыта';
  TEXT_SHIFT_EXPIRED = 'истекла';

  RESULT_COMMAND_OK = 'OK';
  TYPE_OF_CHECK_SELL = 'sell';
  TYPE_OF_CHECK_RETURN = 'return';
  
  // Пути к CSV файлам
  CSV_INPUT_MARKS = 'c:\share\checkmarks\input_marks.csv';        // Входной файл с марками от 1С
  CSV_INPUT_GENERAL_PARAMS = 'c:\share\checkmarks\params_of_programm.csv';      // общие параметры программы
  CSV_INPUT_PARAMS = 'c:\share\checkmarks\input_params.csv';      // Параметры чека (кассир, тип, таймзона)
  CSV_OUTPUT_RESULTS = 'c:\share\checkmarks\output_results.csv';  // Выходной файл с результатами для 1С
  CSV_PROGRESS_INFO = 'c:\share\checkmarks\progress_info.csv';    // Файл с информацией о прогрессе проверки
  COMMAND_PATH = 'c:\share\checkmarks\commands\';
  LOGS_PATH = 'c:\share\checkmarks\logs\';                        // Папка для файлов логов

  PLANNED_STATUS_OF_MARK_PIECE_SOLD = 'штучный товар, реализован';
  PLANNED_STATUS_OF_MARK_DRY_FOR_SALE = 'мерный товар, в стадии реализации';
  PLANNED_STATUS_OF_PIECE_RETURN = 'штучный товар, возвращен';
  PLANNED_STATUS_OF_DRY_RETURN = 'штучный товар, в стадии реализации';
  PLANNED_STATUS_OF_PIECE_FOR_SALE = 'штучный товар, в стадии реализации';
  PLANNED_STATUS_OF_DRY_SOLD = 'мерный товар, реализован';
  PLANNED_STATUS_OF_UNCHANGED = 'статус товара не изменился';

  COMMANDS_FROM_1C_PROCCES_NEW = 'new';
  COMMANDS_FROM_1C_PROCCES_RECEIPT = 'process';
  COMMANDS_FROM_1C_CANCEL_RECEIPT = 'cancel';
  COMMANDS_FROM_1C_CLOSING_RECEIPT = 'closing';
  COMMANDS_FROM_1C_CLOSED_RECEIPT = 'closed';
  COMMANDS_FROM_1C_PRINT_RECEIPT = 'print_receipt';
  
  // Файлы для печати чека через JSON
  CSV_RECEIPT_REQUEST = 'c:\share\checkmarks\receipt_request.json';   // Входной JSON чека от 1С
  CSV_RECEIPT_RESPONSE = 'c:\share\checkmarks\receipt_response.json'; // Выходной результат для 1С

type
  // Структура входных данных о марке
  TInputMark = record
    Position: Integer;
    MarkCode: string;
    MarkCodeBase64: string;
    MarkCodeKI: string;
    PlannedStatus: string;
  end;

  // Структура параметров чека
  RGeneralParams = record
    TimeZone: Integer;
    NumComPort: integer;     // Номер COM порта или "Нет"
    vklRR: Boolean;          // Включение РР: "localhost" или IP адрес
    IpRR: string;           // IP адрес РР
    PortRR: Integer;        // Порт РР
    test: Boolean;          // Тестовый режим
    EmulWaitFromOISM: Boolean;  // Эмуляция ожидания от ОИСМ
    EmulMistFromOISM: Boolean;  // Эмуляция ошибки от ОИСМ
    OpenConnectOnRunProgramm: boolean;
    KeepConnectWhileRunProgramm: boolean;
    EmulationTormozaKKT:boolean; //эмуляция тормозов ККТ
    PauseTormozovKKTInSeconds:integer; //пауза в секундах эмуляции ККТ
  end;

  // Структура параметров чека
  RCheckParams = record
    INNFirmy:string; //ИНН Фирмы
    CheckType: string;      // sell / return
    CashierName: string;
    TimeZone: Integer;
    NumComPort: integer;     // Номер COM порта или "Нет"
    vklRR: Boolean;          // Включение РР: "localhost" или IP адрес
    IpRR: string;           // IP адрес РР
    PortRR: Integer;        // Порт РР
    test: Boolean;          // Тестовый режим
    EmulWaitFromOISM: Boolean;  // Эмуляция ожидания от ОИСМ
    EmulMistFromOISM: Boolean;  // Эмуляция ошибки от ОИСМ
  end;

  // Структура результата проверки марки
  TMarkResult = record
    Position: Integer;
    MarkCodeBase64: string;
    CheckTime: TDateTime;   // Время проверки для кэша
    // Результаты проверки на ККТ
    KKTCheckCode: Integer;
    KKTCheckDescription: string;
    ValidationResult:integer;
    // Результаты проверки по разрешительному режиму (если будет)
    PermitCheckCode: Integer;
    PermitCheckDescription: string;
    UUID: string;
    TimeStamp: string;
    Inst: string;
    Ver: string;
  end;

  TCheckMarksForm = class(TForm)
    MemoMarks: TMemo;
    EditSellOrReturn: TEdit;
    ButtonCheckMarksOnKKT: TButton;
    ResultCodeCheckOnKKTEdit: TEdit;
    ResultDescrCheckOnKKTEdit: TEdit;
    CreateDriverKKTButton: TButton;
    CheckMarkOnKKTButton: TButton;
    EditCurrentMarkBase64: TEdit;
    ButtonCheckStatusKKT: TButton;
    ButtonCheckPermitMark: TButton;
    EditCodeResultCheckPermit: TEdit;
    EditDescrResultPerimtCheck: TEdit;
    ButtonCheckPermitMarks: TButton;
    ButtonCheckMark: TButton;
    ButtonCheckMArks: TButton;
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
    LogsMemo: TMemo;
    ButtonGetMarksForCheck: TButton;
    LabelCaptionResultCheckOfMark: TLabel;
    MemoResult: TMemo;
    ButtonAddToTable: TButton;
    ButtonSaveResults: TButton;
    EditValidationResult: TEdit;
    ButtonGetNextMark: TButton;
    EditUUID: TEdit;
    EditTimeStamp: TEdit;
    EditInst: TEdit;
    EditVer: TEdit;
    EditCurrentMark: TEdit;
    EditCurrentMarkCodeIdent: TEdit;
    ButtonRecieptWasClosed: TButton;
    ButtonCancelRecipt: TButton;
    ButtonReceiptClosing: TButton;
    TimerForCommandsFrom1c: TTimer;
    TimerCheckMarks: TTimer;
    LabelLastCommand: TLabel;
    CheckRRVkl: TCheckBox;
    CheckBoxEmulWaitOISM: TCheckBox;
    CheckBoxEmulMistOISM: TCheckBox;
    EditIpRR: TEdit;
    EditPortRR: TEdit;
    EditComPortKKT: TEdit;
    ButtonStopLog: TButton;
    ButtonBeginLog: TButton;
    EditINNFirmy: TEdit;
    LabelVersionCaption: TLabel;
    Button1: TButton;
    DonCloseConnectionWithKKTCheckBox: TCheckBox;
    CheckBoxEmulationTormoz: TCheckBox;
    EditPauseTormozaKKTEmul: TEdit;
    procedure ButtonGetMarksForCheckClick(Sender: TObject);
    procedure CreateDriverKKTButtonClick(Sender: TObject);
    procedure ButtonConnectToKKTClick(Sender: TObject);
    procedure ButtonCheckStatusKKTClick(Sender: TObject);
    procedure ButtonOpenShiftIfNeedClick(Sender: TObject);
    procedure CheckMarkOnKKTButtonClick(Sender: TObject);
    procedure ButtonDissconnectFromKKTClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonGetNextMarkClick(Sender: TObject);
    procedure ButtonAddToTableClick(Sender: TObject);
    procedure ButtonSaveResultsClick(Sender: TObject);
    procedure ButtonRecieptWasClosedClick(Sender: TObject);
    procedure ButtonCancelReciptClick(Sender: TObject);
    procedure ButtonReceiptClosingClick(Sender: TObject);
    procedure TimerForCommandsFrom1cTimer(Sender: TObject);
    procedure ButtonReceiptProcessClick(Sender: TObject);
    procedure TimerCheckMarksTimer(Sender: TObject);
    procedure ButtonCheckPermitMarkClick(Sender: TObject);
    procedure ButtonDestroyDiverKKTClick(Sender: TObject);
    procedure ButtonStopLogClick(Sender: TObject);
    procedure ButtonBeginLogClick(Sender: TObject);
  private
    { Private declarations }
    fptr: OLEVariant;
    FInputMarks: TArray<TInputMark>;       // Загруженные марки из CSV
    FGeneralParams: RGeneralParams;
    FCheckParams: RCheckParams;             // Параметры чека
    FCheckCache: TArray<TMarkResult>;       // Кэш проверенных марок (сохраняется в CSV)
    FLogMemo: TMemo;                        // Memo для логирования (устанавливается позже)
    FLogFileName: string;                   // Имя текущего файла лога
    FClosingRecipt:boolean;
    FStopLog:boolean;
    procedure ClearCheckMarkResault;
    function MarkInputToStr(InputMark: TInputMark):string;
    function MarkResultToStr(R: TMarkResult):string;
    function LoadInputMarksFromCSV: Boolean;
    function LoadGeneralParamsFromCSV: Boolean;
    function LoadCheckParamsFromCSV: Boolean;
    function SaveResultsToCSV: Boolean;
    procedure ClearAllData;
    procedure InitLogFile;
    procedure CleanOldLogs;
    procedure LogMessage(const Msg: string);
    procedure LogToFile(const Msg: string);
    function FindMarkInCache(const MarkCodeBase64: string; out CachedResult: TMarkResult): Boolean;
    procedure AddMarkToCache(const MarkResult: TMarkResult);
    function MarkExistsInInputArray(const MarkCodeBase64: string): Boolean;
    procedure ProcessMarkCode(var Mark: TInputMark);
    function CheckMarkByPermitMode(const MarkCode: string; const IPServer: string; Port: Integer): TMarkResult;
    procedure SaveProgressInfo(CurrentPosition: Integer);
    function ExecuteReceiptJSON(const RequestJSON: string; out ResponseJSON: string; out ErrorCode: Integer; out ErrorDescription: string): Boolean;
    function GetMockReceiptResponse(const RequestJSON: string): string;
    procedure ProcessPrintReceiptCommand();
  public
    { Public declarations }
    // Инициализация: установите FLogMemo в нужный TMemo компонент
    // Например, в FormCreate или где угодно:
    // FLogMemo := MemoTasks;  // или любой другой TMemo
  end;

var
  CheckMarksForm: TCheckMarksForm;

implementation

{$R *.dfm}

// === ФУНКЦИИ РАБОТЫ С CSV ФАЙЛАМИ ===

// Загрузка марок из входного CSV файла
function TCheckMarksForm.LoadInputMarksFromCSV: Boolean;
var
  Lines: TStringList;
  i: Integer;
  Fields: TArray<string>;
  Mark: TInputMark;
begin
  Result := False;
  SetLength(FInputMarks, 0);
  MemoMarks.Clear;
  
  if not FileExists(CSV_INPUT_MARKS) then
  begin
    LogMessage('ОШИБКА: Файл с марками не найден: ' + CSV_INPUT_MARKS);
    Exit;
  end;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(CSV_INPUT_MARKS, TEncoding.UTF8);

    // Пропускаем заголовок (первую строку)
    for i := 1 to Lines.Count - 1 do
    begin
      if Trim(Lines[i]) = '' then Continue;

      Fields := Lines[i].Split([';']);
      if Length(Fields) < 3 then Continue;

      Mark.Position := StrToIntDef(Trim(Fields[0]), 0);
      Mark.MarkCodeBase64 := Trim(Fields[1]);
      Mark.PlannedStatus := Trim(Fields[2]);
      
      // Обрабатываем код марки: декодируем и извлекаем КИ
      ProcessMarkCode(Mark);

      // Проверяем, нет ли уже такой марки в массиве
      if MarkExistsInInputArray(Mark.MarkCodeBase64) then
      begin
        LogMessage('ПРЕДУПРЕЖДЕНИЕ: Марка уже есть в списке, пропускаем дубликат. Позиция: ' + IntToStr(Mark.Position));
        Continue;
      end;

      MemoMarks.Lines.Add(MarkInputToStr(Mark));

      SetLength(FInputMarks, Length(FInputMarks) + 1);
      FInputMarks[High(FInputMarks)] := Mark;
      //LogMessage(MarkInputToStr(Mark));
    end;

    Result := Length(FInputMarks) > 0;
  finally
    Lines.Free;
  end;
end;

// Загрузка параметров чека из CSV файла
function TCheckMarksForm.LoadGeneralParamsFromCSV: Boolean;
var
  Lines: TStringList;
  Fields: TArray<string>;
begin
  Result := False;

  FGeneralParams.NumComPort:=0;
  FGeneralParams.vklRR:=false;
  FGeneralParams.IpRR:='localhost';
  FGeneralParams.PortRR:=2578;
  FGeneralParams.test:=true;
  FGeneralParams.EmulWaitFromOISM:=false;
  FGeneralParams.EmulMistFromOISM:=false;
  FGeneralParams.OpenConnectOnRunProgramm:=true;
  FGeneralParams.KeepConnectWhileRunProgramm:=true;
  FGeneralParams.EmulationTormozaKKT:=false;
  FGeneralParams.PauseTormozovKKTInSeconds:=60;

  if not FileExists(CSV_INPUT_GENERAL_PARAMS) then
  begin
    LogMessage('Предупреждение: Файл с параметрами запуска программы не найден: ' + CSV_INPUT_GENERAL_PARAMS);
    Exit;
  end;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(CSV_INPUT_GENERAL_PARAMS, TEncoding.UTF8);

    if Lines.Count < 2 then Exit;

    // Вторая строка - данные (первая - заголовок)
    Fields := Lines[1].Split([';']);
    if Length(Fields) < 3 then
    begin
      LogMessage('ОШИБКА: Недостаточно параметров в CSV файле (ожидается 10, получено ' + IntToStr(Length(Fields)) + ')');
      Exit;
    end;

    // Базовые параметры
    FGeneralParams.TimeZone := StrToIntDef(Trim(Fields[0]), 4);

    if Length(Fields) > 3 then begin
      // Новые параметры
      FGeneralParams.NumComPort := StrToIntDef(Trim(Fields[1]), 0);
      FGeneralParams.vklRR := SameText(Trim(Fields[2]), 'Да');
      FGeneralParams.IpRR := Trim(Fields[3]);
      FGeneralParams.PortRR := StrToIntDef(Trim(Fields[4]), 2578);
      FGeneralParams.test := SameText(Trim(Fields[5]), 'Да');
      FGeneralParams.EmulWaitFromOISM := SameText(Trim(Fields[6]), 'Да');
      FGeneralParams.EmulMistFromOISM := SameText(Trim(Fields[7]), 'Да');
      FGeneralParams.OpenConnectOnRunProgramm:=SameText(Trim(Fields[8]), 'Да');
      FGeneralParams.KeepConnectWhileRunProgramm:=SameText(Trim(Fields[9]), 'Да');
      FGeneralParams.EmulationTormozaKKT:=SameText(Trim(Fields[10]), 'Нет');
      FGeneralParams.PauseTormozovKKTInSeconds := StrToIntDef(Trim(Fields[11]), 60);

      LogMessage('Параметры запуска программы: ComPort=' + IntToStr(FGeneralParams.NumComPort) +
                 ', vklRR=' + BoolToStr(FGeneralParams.vklRR, true) +
                 ', IP=' + FGeneralParams.IpRR +
                 ', Port=' + IntToStr(FGeneralParams.PortRR) +
                 ', Test=' + BoolToStr(FGeneralParams.test, False) +
                 ', EmulWait=' + BoolToStr(FGeneralParams.EmulWaitFromOISM, False) +
                 ', EmulMist=' + BoolToStr(FGeneralParams.EmulMistFromOISM, False) +
                 ', OpenConnectOnRunProgramm=' + BoolToStr(FGeneralParams.OpenConnectOnRunProgramm, False) +
                 ', KeepConnectWhileRunProgramm=' + BoolToStr(FGeneralParams.KeepConnectWhileRunProgramm, False) +
                 ', EmulationTormozaKKT=' + BoolToStr(FGeneralParams.EmulationTormozaKKT, False) +
                 ', PauseTormozovKKTInSeconds=' + IntToStr(FGeneralParams.PauseTormozovKKTInSeconds)
                 );
    end;
    Result := True;
  finally
    Lines.Free;
  end;
end; //LoadGeneralParamsFromCSV


// Загрузка параметров чека из CSV файла
function TCheckMarksForm.LoadCheckParamsFromCSV: Boolean;
var
  Lines: TStringList;
  Fields: TArray<string>;
begin
  Result := False;
  
  if not FileExists(CSV_INPUT_PARAMS) then
  begin
    LogMessage('ОШИБКА: Файл с параметрами чека не найден: ' + CSV_INPUT_PARAMS);
    Exit;
  end;
  
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(CSV_INPUT_PARAMS, TEncoding.UTF8);
    
    if Lines.Count < 2 then Exit;
    
    // Вторая строка - данные (первая - заголовок)
    Fields := Lines[1].Split([';']);
    if Length(Fields) < 3 then
    begin
      LogMessage('ОШИБКА: Недостаточно параметров в CSV файле (ожидается 10, получено ' + IntToStr(Length(Fields)) + ')');
      Exit;
    end;
    
    // Базовые параметры
    FCheckParams.INNFirmy:=Trim(Fields[0]);
    FCheckParams.CheckType := Trim(Fields[1]);
    FCheckParams.CashierName := Trim(Fields[2]);
    FCheckParams.TimeZone := StrToIntDef(Trim(Fields[3]), 6);

    FCheckParams.NumComPort:=0;
    FCheckParams.vklRR:=true;
    FCheckParams.IpRR:='localhost';
    FCheckParams.PortRR:=2578;
    FCheckParams.test:=false;
    FCheckParams.EmulWaitFromOISM:=false;
    FCheckParams.EmulMistFromOISM:=false;

    if Length(Fields) > 3 then begin
      // Новые параметры
      FCheckParams.NumComPort := StrToIntDef(Trim(Fields[4]), 0);
      FCheckParams.vklRR := SameText(Trim(Fields[5]), 'Да');
      FCheckParams.IpRR := Trim(Fields[6]);
      FCheckParams.PortRR := StrToIntDef(Trim(Fields[7]), 2578);
      FCheckParams.test := SameText(Trim(Fields[8]), 'Да');
      FCheckParams.EmulWaitFromOISM := SameText(Trim(Fields[9]), 'Да');
      FCheckParams.EmulMistFromOISM := SameText(Trim(Fields[10]), 'Да');

      LogMessage('Параметры загружены: ИНН фирмы = ' + FCheckParams.INNFirmy +
                 ', Тип=' + FCheckParams.CheckType +
                 ', Кассир=' + FCheckParams.CashierName +
                 ', ComPort=' + IntToStr(FCheckParams.NumComPort) +
                 ', vklRR=' + BoolToStr(FCheckParams.vklRR, true) +
                 ', IP=' + FCheckParams.IpRR +
                 ', Port=' + IntToStr(FCheckParams.PortRR) +
                 ', Test=' + BoolToStr(FCheckParams.test, False) +
                 ', EmulWait=' + BoolToStr(FCheckParams.EmulWaitFromOISM, False) +
                 ', EmulMist=' + BoolToStr(FCheckParams.EmulMistFromOISM, False));
    end;
    Result := True;
  finally
    Lines.Free;
  end;
end;

// Сохранение результатов в выходной CSV файл
function TCheckMarksForm.SaveResultsToCSV: Boolean;
var
  Lines: TStringList;
  i: Integer;
  R: TMarkResult;
begin
  Result := False;
  
  Lines := TStringList.Create;
  try
    // Заголовок
    Lines.Add('Position;MarkCode;KKTCheckCode;KKTCheckDescription;' +
              'ValidationResult;' +
              'PermitCheckCode;PermitCheckDescription;UUID;TimeStamp;Inst;Ver');
    
    // Данные из кэша проверок
    for i := 0 to High(FCheckCache) do
    begin
      R := FCheckCache[i];
      Lines.Add(MarkResultToStr(R));
    end;
    
    Lines.SaveToFile(CSV_OUTPUT_RESULTS, TEncoding.UTF8);
    Result := True;
    
    LogMessage('Сохранено результатов: ' + IntToStr(Length(FCheckCache)));
  finally
    Lines.Free;
  end;
end;

// Сохранение информации о прогрессе проверки марок
procedure TCheckMarksForm.SaveProgressInfo(CurrentPosition: Integer);
var
  Lines: TStringList;
  TotalMarks, CheckedMarks: Integer;
begin
  Lines := TStringList.Create;
  try
    TotalMarks := Length(FInputMarks);
    CheckedMarks := Length(FCheckCache);
    
    // Заголовок
    Lines.Add('CurrentPosition;TotalMarks;CheckedMarks');
    
    // Данные о прогрессе
    Lines.Add(IntToStr(CurrentPosition) + ';' + 
              IntToStr(TotalMarks) + ';' + 
              IntToStr(CheckedMarks));
    
    Lines.SaveToFile(CSV_PROGRESS_INFO, TEncoding.UTF8);
  finally
    Lines.Free;
  end;
end;

// Формирование мок-ответа для режима эмуляции
function TCheckMarksForm.GetMockReceiptResponse(const RequestJSON: string): string;
var
  ResponseObj: TJSONObject;
  FiscalParamsObj: TJSONObject;
  CurrentDateTime: TDateTime;
  DateTimeStr: string;
begin
  ResponseObj := TJSONObject.Create;
  try
    // Определяем тип операции по содержимому запроса
    
    // Если это продажа (sell) или возврат (sellReturn)
    if (Pos('sell', LowerCase(RequestJSON)) > 0) or (Pos('sellReturn', LowerCase(RequestJSON)) > 0) then
    begin
      // Формируем fiscalParams - фискальные параметры чека
      FiscalParamsObj := TJSONObject.Create;
      
      CurrentDateTime := Now;
      DateTimeStr := FormatDateTime('yyyy-mm-dd', CurrentDateTime) + 'T' + 
                     FormatDateTime('hh:nn:ss', CurrentDateTime) + '+03:00';
      
      FiscalParamsObj.AddPair('fiscalDocumentDateTime', DateTimeStr);
      FiscalParamsObj.AddPair('fiscalDocumentNumber', TJSONNumber.Create(123));
      FiscalParamsObj.AddPair('fiscalDocumentSign', '1494325660');
      FiscalParamsObj.AddPair('fiscalReceiptNumber', TJSONNumber.Create(1));
      FiscalParamsObj.AddPair('fnNumber', '9999078900000961');
      FiscalParamsObj.AddPair('registrationNumber', '0000000001002292');
      FiscalParamsObj.AddPair('shiftNumber', TJSONNumber.Create(12));
      FiscalParamsObj.AddPair('total', TJSONNumber.Create(72.34));
      FiscalParamsObj.AddPair('fnsUrl', 'www.nalog.gov.ru');
      
      ResponseObj.AddPair('fiscalParams', FiscalParamsObj);
      ResponseObj.AddPair('warnings', '');
    end
    // Если это закрытие смены (closeShift)
    else if Pos('closeShift', LowerCase(RequestJSON)) > 0 then
    begin
      FiscalParamsObj := TJSONObject.Create;
      
      CurrentDateTime := Now;
      DateTimeStr := FormatDateTime('yyyy-mm-dd', CurrentDateTime) + 'T' + 
                     FormatDateTime('hh:nn:ss', CurrentDateTime) + '+03:00';
      
      FiscalParamsObj.AddPair('fiscalDocumentDateTime', DateTimeStr);
      FiscalParamsObj.AddPair('fiscalDocumentNumber', TJSONNumber.Create(456));
      FiscalParamsObj.AddPair('fiscalDocumentSign', '2345678901');
      FiscalParamsObj.AddPair('fnNumber', '9999078900000961');
      FiscalParamsObj.AddPair('registrationNumber', '0000000001002292');
      FiscalParamsObj.AddPair('shiftNumber', TJSONNumber.Create(12));
      
      ResponseObj.AddPair('fiscalParams', FiscalParamsObj);
      ResponseObj.AddPair('warnings', '');
    end
    // Если это открытие смены (openShift)
    else if Pos('openShift', LowerCase(RequestJSON)) > 0 then
    begin
      FiscalParamsObj := TJSONObject.Create;
      
      CurrentDateTime := Now;
      DateTimeStr := FormatDateTime('yyyy-mm-dd', CurrentDateTime) + 'T' + 
                     FormatDateTime('hh:nn:ss', CurrentDateTime) + '+03:00';
      
      FiscalParamsObj.AddPair('fiscalDocumentDateTime', DateTimeStr);
      FiscalParamsObj.AddPair('fiscalDocumentNumber', TJSONNumber.Create(1));
      FiscalParamsObj.AddPair('fiscalDocumentSign', '1234567890');
      FiscalParamsObj.AddPair('fnNumber', '9999078900000961');
      FiscalParamsObj.AddPair('registrationNumber', '0000000001002292');
      FiscalParamsObj.AddPair('shiftNumber', TJSONNumber.Create(12));
      
      ResponseObj.AddPair('fiscalParams', FiscalParamsObj);
      ResponseObj.AddPair('warnings', '');
    end
    // Для всех остальных операций - простой ответ
    else
    begin
      ResponseObj.AddPair('result', 'OK');
      ResponseObj.AddPair('emulation', TJSONBool.Create(True));
    end;
    
    Result := ResponseObj.ToString;
    
  finally
    ResponseObj.Free;
  end;
end;

// Выполнение JSON команды на ККТ
function TCheckMarksForm.ExecuteReceiptJSON(const RequestJSON: string; out ResponseJSON: string; 
  out ErrorCode: Integer; out ErrorDescription: string): Boolean;
var
  CloseConnection: Boolean;
  NomComPorta: Integer;
begin
  Result := False;
  ResponseJSON := '';
  ErrorCode := 0;
  ErrorDescription := 'OK';
  CloseConnection := not DonCloseConnectionWithKKTCheckBox.Checked; // Закрываем соединение после выполнения

  try
    LogMessage('=== ВЫПОЛНЕНИЕ JSON КОМАНДЫ ===');
    LogMessage('JSON запрос: ' + RequestJSON);
    
    // Подключаемся к ККТ если не эмуляция
    if not CheckBoxEmulationKKT.Checked then
    begin
      if not fptr.isOpened then
      begin
        NomComPorta := StrToIntDef(EditComPortKKT.Text, 0);
        if NomComPorta > 0 then
        begin
          fptr.setSingleSetting(fptr.LIBFPTR_SETTING_PORT, fptr.LIBFPTR_PORT_COM);
          fptr.setSingleSetting(fptr.LIBFPTR_SETTING_COM_FILE, NomComPorta);
          fptr.setSingleSetting(fptr.LIBFPTR_SETTING_BAUDRATE, fptr.LIBFPTR_PORT_BR_115200);
        end
        else
          fptr.setSingleSetting(fptr.LIBFPTR_SETTING_PORT, fptr.LIBFPTR_PORT_USB);
        fptr.setSingleSetting(fptr.LIBFPTR_SETTING_TIME_ZONE, ComboBoxTimeZone.ItemIndex + 1);
        fptr.applySingleSettings;
        fptr.open;
        
        if not fptr.isOpened then
        begin
          ErrorCode := fptr.errorCode;
          ErrorDescription := fptr.errorDescription;
          LogMessage('ОШИБКА подключения к ККТ: ' + ErrorDescription);
          Exit;
        end;
      end;
    end;
    
    // Выполняем JSON команду через драйвер
    if CheckBoxEmulationKKT.Checked then
    begin
      // Эмуляция - возвращаем реалистичный мок-ответ
      ResponseJSON := GetMockReceiptResponse(RequestJSON);
      ErrorCode := 0;
      ErrorDescription := 'OK (эмуляция)';
      LogMessage('Эмуляция: команда выполнена успешно');
      LogMessage('Мок-ответ: ' + ResponseJSON);
    end
    else
    begin
      // Реальное выполнение через драйвер
      fptr.setParam(fptr.LIBFPTR_PARAM_JSON_DATA, RequestJSON);
      fptr.processJson;
      
      ErrorCode := fptr.errorCode;
      if ErrorCode <> 0 then
      begin
        ErrorDescription := fptr.errorDescription;
        LogMessage('ОШИБКА выполнения JSON: [' + IntToStr(ErrorCode) + '] ' + ErrorDescription);
      end
      else
      begin
        ResponseJSON := fptr.getParamString(fptr.LIBFPTR_PARAM_JSON_DATA);
        ErrorDescription := 'OK';
        LogMessage('JSON команда выполнена успешно');
        LogMessage('JSON ответ: ' + ResponseJSON);
      end;
    end;
    
    // Закрываем соединение если нужно
    if CloseConnection and not CheckBoxEmulationKKT.Checked then
    begin
      fptr.close;
      LogMessage('Отключились от ККТ');
    end;
    
    Result := (ErrorCode = 0);
    
  except
    on E: Exception do
    begin
      ErrorCode := -1;
      ErrorDescription := 'Исключение: ' + E.Message;
      LogMessage('ОШИБКА: ' + ErrorDescription);
      Result := False;
    end;
  end;
end;

// Обработка команды печати чека через JSON
procedure TCheckMarksForm.ProcessPrintReceiptCommand();
var
  RequestJSON: string;
  ResponseJSON: string;
  ErrorCode: Integer;
  ErrorDescription: string;
  ResponseLines: TStringList;
  ResponseObj: TJSONObject;
begin
  try
    LogMessage('=== ОБРАБОТКА КОМАНДЫ ПЕЧАТИ ЧЕКА ===');
    
    // Проверяем наличие файла с запросом
    if not FileExists(CSV_RECEIPT_REQUEST) then
    begin
      LogMessage('ОШИБКА: Файл с JSON чека не найден: ' + CSV_RECEIPT_REQUEST);
      Exit;
    end;
    
    // Читаем JSON из файла
    try
      var Lines := TStringList.Create;
      try
        Lines.LoadFromFile(CSV_RECEIPT_REQUEST, TEncoding.UTF8);
        RequestJSON := Lines.Text;
        LogMessage('Прочитан JSON чека, размер: ' + IntToStr(Length(RequestJSON)) + ' символов');
      finally
        Lines.Free;
      end;
    except
      on E: Exception do
      begin
        LogMessage('ОШИБКА чтения файла запроса: ' + E.Message);
        Exit;
      end;
    end;
    
    // Выполняем команду
    if ExecuteReceiptJSON(RequestJSON, ResponseJSON, ErrorCode, ErrorDescription) then
      LogMessage('✓ Печать чека выполнена успешно')
    else
      LogMessage('✗ Ошибка печати чека: [' + IntToStr(ErrorCode) + '] ' + ErrorDescription);
    
    // Формируем ответ в формате JSON
    ResponseObj := TJSONObject.Create;
    try
      ResponseObj.AddPair('ответJSON', ResponseJSON);
      ResponseObj.AddPair('кодОшибки', TJSONNumber.Create(ErrorCode));
      ResponseObj.AddPair('описаниеОшибки', ErrorDescription);
      
      // Сохраняем ответ в файл
      ResponseLines := TStringList.Create;
      try
        ResponseLines.Text := ResponseObj.ToString;
        ResponseLines.SaveToFile(CSV_RECEIPT_RESPONSE, TEncoding.UTF8);
        LogMessage('✓ Результат сохранен в файл: ' + CSV_RECEIPT_RESPONSE);
      finally
        ResponseLines.Free;
      end;
    finally
      ResponseObj.Free;
    end;
    
    // Удаляем файл запроса после обработки
    try
      TFile.Delete(CSV_RECEIPT_REQUEST);
      LogMessage('✓ Файл запроса удален');
    except
      on E: Exception do
        LogMessage('ПРЕДУПРЕЖДЕНИЕ: Не удалось удалить файл запроса: ' + E.Message);
    end;
    
  except
    on E: Exception do
    begin
      LogMessage('КРИТИЧЕСКАЯ ОШИБКА при обработке команды печати чека: ' + E.Message);
      
      // Пытаемся сохранить ошибку в файл ответа
      try
        ResponseObj := TJSONObject.Create;
        try
          ResponseObj.AddPair('ответJSON', '');
          ResponseObj.AddPair('кодОшибки', TJSONNumber.Create(-1));
          ResponseObj.AddPair('описаниеОшибки', 'Критическая ошибка: ' + E.Message);
          
          ResponseLines := TStringList.Create;
          try
            ResponseLines.Text := ResponseObj.ToString;
            ResponseLines.SaveToFile(CSV_RECEIPT_RESPONSE, TEncoding.UTF8);
          finally
            ResponseLines.Free;
          end;
        finally
          ResponseObj.Free;
        end;
      except
        // Игнорируем ошибки при попытке сохранить ошибку
      end;
    end;
  end;
end;

// Таймер для проверки команд от 1С через файловую систему
procedure TCheckMarksForm.TimerCheckMarksTimer(Sender: TObject);
begin
 TimerCheckMarks.Enabled:=false;
 if FClosingRecipt then exit;
 ButtonReceiptProcessClick(self); //запускам процесс проверки марок, и далее с периодичностью несколько секунд
end;

procedure TCheckMarksForm.TimerForCommandsFrom1cTimer(Sender: TObject);
var
  CommandFiles: TArray<string>;
  CommandFile: string;
  CommandName: string;
begin
  try
    // Проверяем существование папки команд
    if not TDirectory.Exists(COMMAND_PATH) then
    begin
      TDirectory.CreateDirectory(COMMAND_PATH);
      Exit;
    end;

    // Получаем все файлы из папки команд
    CommandFiles := TDirectory.GetFiles(COMMAND_PATH, '*.*');

    if Length(CommandFiles) = 0 then
      Exit; // Нет команд

    //отключаем таймер, пока не отработают команды
    TimerForCommandsFrom1c.Enabled:=false;

    // Обрабатываем каждый файл команды
    for CommandFile in CommandFiles do
    begin
      // Извлекаем имя команды (без расширения и пути)
      CommandName := TPath.GetFileNameWithoutExtension(CommandFile);

      LogMessage('Получена команда от 1С: ' + CommandName);

      if CommandName = COMMANDS_FROM_1C_PROCCES_NEW then
      begin
        // Команда: новый чек
        LogMessage('→ Команда: НОВЫЙ ЧЕК');
        ButtonCancelReciptClick(Self);
      end
      else if CommandName = COMMANDS_FROM_1C_PRINT_RECEIPT then
      begin
        // Команда: печать чека через JSON
        LogMessage('→ Команда: ПЕЧАТЬ ЧЕКА (JSON)');
        ProcessPrintReceiptCommand();
      end
      // Выполняем команду в зависимости от имени
      else if CommandName = COMMANDS_FROM_1C_PROCCES_RECEIPT then
      begin
        // Команда: начать обработку чека
        LogMessage('→ Команда: НАЧАТЬ ОБРАБОТКУ ЧЕКА');
        ButtonReceiptProcessClick(Self);
        //ButtonReceiptProcessClick(Self);
      end
      else if CommandName = COMMANDS_FROM_1C_CANCEL_RECEIPT then
      begin
        // Команда: отменить чек
        LogMessage('→ Команда: ОТМЕНИТЬ ЧЕК');
        ButtonCancelReciptClick(Self);
      end
      else if CommandName = COMMANDS_FROM_1C_CLOSING_RECEIPT then
      begin
        // Команда: чек закрывается
        LogMessage('→ Команда: ЧЕК ЗАКРЫВАЕТСЯ');
        ButtonReceiptClosingClick(Self);
      end
      else if CommandName = COMMANDS_FROM_1C_CLOSED_RECEIPT then
      begin
        // Команда: чек закрыт
        LogMessage('→ Команда: ЧЕК ЗАКРЫТ');
        ButtonRecieptWasClosedClick(Self);
      end
      else
      begin
        LogMessage('ПРЕДУПРЕЖДЕНИЕ: Неизвестная команда: ' + CommandName);
      end;

      LabelLastCommand.Caption:=CommandName;
      
      // УДАЛЯЕМ файл команды сразу после получения
      try
        TFile.Delete(CommandFile);
        LogMessage('✓ Файл команды удален: ' + TPath.GetFileName(CommandFile));
      except
        on E: Exception do
          LogMessage('ОШИБКА удаления файла команды: ' + E.Message);
      end;
    end;
    
  except
    on E: Exception do
    begin
      LogMessage('ОШИБКА обработки команд: ' + E.Message);
    end;
  end;

  TimerForCommandsFrom1c.Enabled:=true;
end;

procedure TCheckMarksForm.ButtonGetMarksForCheckClick(Sender: TObject);
begin
  LabelResultCommandCode.Caption:='0';
  LabelResultCommandDescr.Caption:=RESULT_COMMAND_OK;
  if LoadCheckParamsFromCSV then
  begin
    EditINNFirmy.Text:=FCheckParams.INNFirmy;
    CheckBoxEmulationKKT.Checked:=FCheckParams.test;
    CheckRRVkl.Checked:=FCheckParams.vklRR;
    EditIpRR.Text:=FCheckParams.IpRR;
    EditPortRR.Text:=IntToStr(FCheckParams.PortRR);
    EditComPortKKT.Text:=IntToStr(FCheckParams.NumComPort);
    CheckBoxEmulWaitOISM.Checked:=FCheckParams.EmulWaitFromOISM;
    //CheckBoxEmulMistOISM.Checked:=FCheckParams.EmulMistFromOISM;

    ComboBoxTimeZone.ItemIndex:=FCheckParams.TimeZone-1;
  end;
  if not(LoadInputMarksFromCSV()) then begin
    LabelResultCommandCode.Caption := '100';
    LabelResultCommandDescr.Caption:='Ошибка загрузки марок для проверки';
  end;
end;

// Получить следующую непроверенную марку
procedure TCheckMarksForm.ButtonGetNextMarkClick(Sender: TObject);
var
  i: Integer;
  cachedResult: TMarkResult;
  found: Boolean;
begin

  ClearCheckMarkResault();
  found := False;
  
  // Проверяем, загружены ли марки
  if Length(FInputMarks) = 0 then
  begin
    LogMessage('Нет загруженных марок. Сначала загрузите данные.');
    Exit;
  end;
  
  // Ищем первую непроверенную марку
  for i := 0 to High(FInputMarks) do
  begin
    // Проверяем, есть ли марка в кэше (по MarkCodeBase64)
    if not FindMarkInCache(FInputMarks[i].MarkCodeBase64, cachedResult) then
    begin
      // Нашли непроверенную марку!
      
      // Заполняем все три поля с кодами марки
      EditCurrentMarkBase64.Text := FInputMarks[i].MarkCodeBase64;
      EditCurrentMark.Text := FInputMarks[i].MarkCode;
      EditCurrentMarkCodeIdent.Text := FInputMarks[i].MarkCodeKI;
      
      // Устанавливаем планируемый статус в ComboBox
      ComboBoxPlannedStatusOfMark.ItemIndex := ComboBoxPlannedStatusOfMark.Items.IndexOf(FInputMarks[i].PlannedStatus);
      
      // Если статус не найден в списке, логируем предупреждение
      if ComboBoxPlannedStatusOfMark.ItemIndex = -1 then
      begin
        LogMessage('ПРЕДУПРЕЖДЕНИЕ: Статус "' + FInputMarks[i].PlannedStatus + '" не найден в ComboBox');
        ComboBoxPlannedStatusOfMark.ItemIndex := 0; // Устанавливаем первый элемент по умолчанию
      end;

      LogMessage('Найдена непроверенная марка:');
      LogMessage('  Позиция: ' + IntToStr(FInputMarks[i].Position));
      LogMessage('  Base64: ' + FInputMarks[i].MarkCodeBase64);
      LogMessage('  Код: ' + FInputMarks[i].MarkCode);
      LogMessage('  КИ: ' + FInputMarks[i].MarkCodeKI);
      LogMessage('  Статус: ' + FInputMarks[i].PlannedStatus);
      LogMessage('  Осталось проверить: ' + IntToStr(Length(FInputMarks) - Length(FCheckCache)));
      
      // Сохраняем информацию о прогрессе в файл для 1С
      SaveProgressInfo(FInputMarks[i].Position);
      
      found := True;
      Exit;
    end;
  end;
  
  // Если все марки уже проверены
  if not found then
  begin
    EditCurrentMark.Text := '';
    EditCurrentMarkBase64.Text:='';
    EditCurrentMarkCodeIdent.Text:='';
    LogMessage('✓ Все марки уже проверены!');
    LogMessage('  Всего марок: ' + IntToStr(Length(FInputMarks)));
    LogMessage('  Проверено: ' + IntToStr(Length(FCheckCache)));
    
    // Сохраняем информацию о завершении проверки всех марок
    if Length(FInputMarks) > 0 then
      SaveProgressInfo(0); // 0 означает, что все проверки завершены
  end;
end;

procedure TCheckMarksForm.ClearCheckMarkResault;
begin
  ResultCodeCheckOnKKTEdit.Text:='';
  ResultDescrCheckOnKKTEdit.Text:='';
  EditValidationResult.Text:='';
  EditCodeResultCheckPermit.Text:='';
  EditDescrResultPerimtCheck.Text:='';
  EditUUID.Text:='';
  EditTimeStamp.Text:='';
  EditInst.Text:='';
  EditVer.Text:='';
end;

procedure TCheckMarksForm.ClearAllData;
begin
  SetLength(FInputMarks, 0);
  SetLength(FCheckCache, 0);
  FCheckParams.CheckType := '';
  FCheckParams.CashierName := '';
  FCheckParams.TimeZone := 4;
  LogMessage('Все данные очищены, кэш сброшен');
end;

// === КОНЕЦ ФУНКЦИЙ РАБОТЫ С CSV ===

// === ФУНКЦИИ РАБОТЫ С КЭШЕМ ПРОВЕРОК ===

// Поиск марки в кэше проверок
function TCheckMarksForm.FindMarkInCache(const MarkCodeBase64: string; out CachedResult: TMarkResult): Boolean;
var
  i: Integer;
begin
  Result := False;
  CachedResult := Default(TMarkResult);
  
  for i := 0 to High(FCheckCache) do
  begin
    if FCheckCache[i].MarkCodeBase64 = MarkCodeBase64 then
    begin
      CachedResult := FCheckCache[i];
      Result := True;
      Exit;
    end;
  end;
end;

procedure TCheckMarksForm.FormCreate(Sender: TObject);
begin
 FStopLog:=false;
 FClosingRecipt:=false;
 FLogMemo:=LogsMemo;
 
 // Инициализируем логирование в файл
 InitLogFile;

 LoadGeneralParamsFromCSV();

 CheckBoxEmulationKKT.Checked:=FGeneralParams.test;
 CheckRRVkl.Checked:=FGeneralParams.vklRR;
 EditIpRR.Text:=FGeneralParams.IpRR;
 EditPortRR.Text:=IntToStr(FGeneralParams.PortRR);
 EditComPortKKT.Text:=IntToStr(FGeneralParams.NumComPort);
 CheckBoxEmulWaitOISM.Checked:=FGeneralParams.EmulWaitFromOISM;
 CheckBoxEmulationTormoz.Checked:=FGeneralParams.EmulationTormozaKKT;
 EditPauseTormozaKKTEmul.Text:=IntToStr(FGeneralParams.PauseTormozovKKTInSeconds);

 FCheckParams.NumComPort:=FGeneralParams.NumComPort;
 FCheckParams.vklRR:=FGeneralParams.vklRR;
 FCheckParams.test:=FGeneralParams.test;
 FCheckParams.PortRR:=FGeneralParams.PortRR;
 FCheckParams.NumComPort:=FGeneralParams.NumComPort;
 FCheckParams.EmulWaitFromOISM:=FGeneralParams.EmulWaitFromOISM;

 DonCloseConnectionWithKKTCheckBox.Checked:=FGeneralParams.KeepConnectWhileRunProgramm;

 ComboBoxTimeZone.ItemIndex:=FGeneralParams.TimeZone-1;


 CreateDriverKKTButtonClick(self);

 if FGeneralParams.OpenConnectOnRunProgramm then begin
   ButtonConnectToKKTClick(self);
 end;

end;

// Добавление или обновление результата проверки в кэше
procedure TCheckMarksForm.AddMarkToCache(const MarkResult: TMarkResult);
var
  i: Integer;
  Found: Boolean;
begin
  Found := False;
  
  // Ищем, есть ли уже такая марка в кэше
  for i := 0 to High(FCheckCache) do
  begin
    if FCheckCache[i].MarkCodeBase64 = MarkResult.MarkCodeBase64 then
    begin
      // Марка найдена - ОБНОВЛЯЕМ результат
      FCheckCache[i] := MarkResult;
      Found := True;
      LogMessage('Результат обновлен в кэше для марки на позиции ' + IntToStr(MarkResult.Position));
      Exit;
    end;
  end;
  
  // Марка не найдена - ДОБАВЛЯЕМ новую запись
  if not Found then
  begin
    SetLength(FCheckCache, Length(FCheckCache) + 1);
    FCheckCache[High(FCheckCache)] := MarkResult;
    LogMessage('Результат добавлен в кэш для марки на позиции ' + IntToStr(MarkResult.Position));
  end;
end;

// Проверка существования марки в массиве загруженных марок
function TCheckMarksForm.MarkExistsInInputArray(const MarkCodeBase64: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(FInputMarks) do
  begin
    if FInputMarks[i].MarkCodeBase64 = MarkCodeBase64 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// Обработка кода марки: декодирование Base64 и извлечение КИ
procedure TCheckMarksForm.ProcessMarkCode(var Mark: TInputMark);
var
  DecodedBytes: TBytes;
  SeparatorPos: Integer;
  Encoding: TEncoding;
begin
  // MarkCodeBase64 уже заполнен из CSV
  
  try
    // ДЕКОДИРУЕМ ИЗ BASE64
    DecodedBytes := TNetEncoding.Base64.DecodeStringToBytes(Mark.MarkCodeBase64);
    
    // Преобразуем байты в строку
    Encoding := TEncoding.UTF8;
    Mark.MarkCode := Encoding.GetString(DecodedBytes);
    
    // Извлекаем MarkCodeKI - все символы до #29
    SeparatorPos := Pos(#29, Mark.MarkCode);
    if SeparatorPos > 0 then
      Mark.MarkCodeKI := Copy(Mark.MarkCode, 1, SeparatorPos - 1)
    else
      Mark.MarkCodeKI := Mark.MarkCode; // Если нет разделителя, берем всю строку
      
  except
    on E: Exception do
    begin
      LogMessage('ОШИБКА декодирования Base64 марки: ' + E.Message);
      // Если не удалось декодировать, оставляем как есть
      Mark.MarkCode := Mark.MarkCodeBase64;
      Mark.MarkCodeKI := Mark.MarkCodeBase64;
    end;
  end;
end;

// === КОНЕЦ ФУНКЦИЙ РАБОТЫ С КЭШЕМ ===

// Очистка старых логов (старше 14 дней)
procedure TCheckMarksForm.CleanOldLogs;
var
  LogDir: string;
  LogFiles: TArray<string>;
  LogFile: string;
  FileAge: TDateTime;
  DeletedCount: Integer;
begin
  LogDir := LOGS_PATH;
  
  if not TDirectory.Exists(LogDir) then
    Exit;
    
  DeletedCount := 0;
  
  try
    // Получаем все файлы .log в папке логов
    LogFiles := TDirectory.GetFiles(LogDir, '*.log');
    
    for LogFile in LogFiles do
    begin
      try
        // Получаем дату последней модификации файла
        FileAge := TFile.GetLastWriteTime(LogFile);
        
        // Если файл старше 14 дней, удаляем его
        if DaysBetween(Now, FileAge) > 14 then
        begin
          TFile.Delete(LogFile);
          Inc(DeletedCount);
        end;
      except
        // Игнорируем ошибки при удалении отдельных файлов
      end;
    end;
    
    if DeletedCount > 0 then
    begin
      // Логируем только в Memo, так как файл лога ещё не инициализирован
      if Assigned(FLogMemo) then
        FLogMemo.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] Удалено старых логов: ' + IntToStr(DeletedCount));
    end;
  except
    // Игнорируем любые ошибки при очистке логов
  end;
end;

// Инициализация файла лога
procedure TCheckMarksForm.InitLogFile;
var
  LogDir: string;
begin
  LogDir := LOGS_PATH;
  
  // Создаем папку для логов, если её нет
  if not TDirectory.Exists(LogDir) then
  begin
    try
      TDirectory.CreateDirectory(LogDir);
    except
      on E: Exception do
      begin
        // Если не удалось создать папку, логи не будут писаться в файл
        FLogFileName := '';
        Exit;
      end;
    end;
  end;
  
  // Очищаем старые логи
  CleanOldLogs;
  
  // Формируем имя файла лога с датой и временем
  FLogFileName := LogDir + 'checkmarks_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log';
  
  // Создаем файл и пишем заголовок
  try
    var Lines := TStringList.Create;
    try
      Lines.Add('=== Лог работы программы проверки марок ===');
      Lines.Add('Дата запуска: ' + FormatDateTime('dd.mm.yyyy hh:nn:ss', Now));
      Lines.Add('===================================');
      Lines.Add('');
      Lines.SaveToFile(FLogFileName, TEncoding.UTF8);
    finally
      Lines.Free;
    end;
  except
    on E: Exception do
    begin
      FLogFileName := '';
    end;
  end;
end;

// Запись в файл лога
procedure TCheckMarksForm.LogToFile(const Msg: string);
var
  Writer: TStreamWriter;
begin
  if FLogFileName = '' then
    Exit;
    
  try
    // Открываем файл для добавления с кодировкой UTF-8
    Writer := TStreamWriter.Create(FLogFileName, True, TEncoding.UTF8);
    try
      Writer.WriteLine(Msg);
    finally
      Writer.Free;
    end;
  except
    // Игнорируем ошибки записи в файл
  end;
end;

// Процедура логирования сообщений
procedure TCheckMarksForm.LogMessage(const Msg: string);
var
  LogMsg: string;
begin
  // TODO: Установить FLogMemo := нужный TMemo компонент
  // Например: FLogMemo := MemoTasks;

  LogMsg := '[' + FormatDateTime('hh:nn:ss', Now) + '] ' + Msg;

  if Assigned(FLogMemo) and not(FStopLog) then
  begin
    // Если превышено 500 строк, очищаем Memo
    if FLogMemo.Lines.Count > 500 then
    begin
      FLogMemo.Clear;
      FLogMemo.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] === ЛОГ ОЧИЩЕН (превышено 500 строк) ===');
    end;
    
    FLogMemo.Lines.Add(LogMsg);
  end;

  // Пишем в файл
  LogToFile(LogMsg);

  // Также выводим в консоль для отладки
  {$IFDEF DEBUG}
  OutputDebugString(PChar(Msg));
  {$ENDIF}
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
    cachedResult: TMarkResult;
    markResult: TMarkResult;
begin
    // Очищаем результаты предыдущей проверки
    ResultCodeCheckOnKKTEdit.Text := '0';
    ResultDescrCheckOnKKTEdit.Text := RESULT_COMMAND_OK;

    mark := EditCurrentMark.Text;
    
    // ПРОВЕРЯЕМ КЭШ - если марка уже проверялась, берем результат из кэша (по Base64)
    if FindMarkInCache(EditCurrentMarkBase64.Text, cachedResult) then
    begin
      LogMessage('=== РЕЗУЛЬТАТ ИЗ КЭША ===');
      LogMessage('Марка уже проверялась ранее');
      LogMessage('Время проверки: ' + DateTimeToStr(cachedResult.CheckTime));
      LogMessage('');
      LogMessage('Код результата: ' + IntToStr(cachedResult.KKTCheckCode));
      LogMessage('Описание: ' + cachedResult.KKTCheckDescription);
      ResultCodeCheckOnKKTEdit.Text := IntToStr(cachedResult.KKTCheckCode);
      ResultDescrCheckOnKKTEdit.Text := cachedResult.KKTCheckDescription;
      EditValidationResult.Text := IntToStr(cachedResult.ValidationResult);
      
      // Заполняем поля разрешительного режима из кэша
      EditCodeResultCheckPermit.Text := IntToStr(cachedResult.PermitCheckCode);
      EditDescrResultPerimtCheck.Text := cachedResult.PermitCheckDescription;
      EditUUID.Text := cachedResult.UUID;
      EditTimeStamp.Text := cachedResult.TimeStamp;
      EditInst.Text := cachedResult.Inst;
      EditVer.Text := cachedResult.Ver;
      
      if (cachedResult.KKTCheckCode = 0) and (cachedResult.ValidationResult = 15) then
        LogMessage('✓ Марка валидна (из кэша)')
      else
        LogMessage('✗ Марка невалидна (из кэша)');

      Exit;
    end;

    ButtonConnectToKKTClick(self);

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
    errorDescr:=fptr.errorDescription;
    LogMessage(IntToStr(ErrorCode));
    LogMessage(errorDescr);
    if ErrorCode = 401 then begin //процедура проверки марки уже была запущена
      LogMessage('Процедура проверки уже была запущена');
      fptr.cancelMarkingCodeValidation;

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
      errorDescr:=fptr.errorDescription;
      LogMessage(IntToStr(ErrorCode));
      LogMessage(errorDescr);
    end;


    if (ErrorCode <> 0) and not (CheckBoxEmulationKKT.Checked) then begin
      errorDescr:=fptr.errorDescription;
      ResultCodeCheckOnKKTEdit.Text:=IntToStr(ErrorCode);
      ResultDescrCheckOnKKTEdit.Text:=errorDescr;

      LogMessage(IntToStr(ErrorCode));
      LogMessage(errorDescr);
      ButtonDissconnectFromKKTClick(self);
      exit;
    end;


    if CheckBoxEmulWaitOISM.Checked then begin
     LogMessage('Делаем паузцу в 5 секунд');
     Sleep(5000);
     LogMessage('Пауза закончилась');
    end;

    // Ожидание ответа от ОИСМ с таймаутом 60 секунд
    var StartTime := Now;
    var TimeoutSeconds := 60;

    while True and not (CheckBoxEmulationKKT.Checked) do
    begin
        sleep(300);
        fptr.getMarkingCodeValidationStatus;
        ErrorCode := fptr.errorCode;
        errorDescr:=fptr.errorDescription;

        // Проверка ошибки при запросе статуса
        if (ErrorCode <> 0) then begin
          ResultCodeCheckOnKKTEdit.Text:=IntToStr(ErrorCode);
          ResultDescrCheckOnKKTEdit.Text:=errorDescr;
          LogMessage('Ошибка при запросе статуса проверки марки: ' + errorDescr);
          ButtonDissconnectFromKKTClick(self);
          exit;
        end;
        
        // Проверка готовности результата
        if fptr.getParamBool(fptr.LIBFPTR_PARAM_MARKING_CODE_VALIDATION_READY) then
            break;
        
        // Проверка таймаута (60 секунд)
        if SecondsBetween(Now, StartTime) > TimeoutSeconds then
        begin
          ErrorCode := -1;
          errorDescr := 'Таймаут ожидания ответа от ОИСМ (' + IntToStr(TimeoutSeconds) + ' сек)';
          ResultCodeCheckOnKKTEdit.Text := IntToStr(ErrorCode);
          ResultDescrCheckOnKKTEdit.Text := errorDescr;
          LogMessage('ОШИБКА: ' + errorDescr);
          ButtonDissconnectFromKKTClick(self);
          exit;
        end;
    end;
    //fptr.getMarkingCodeValidationStatus;
   {*if (not fptr.getParamBool(fptr.LIBFPTR_PARAM_MARKING_CODE_VALIDATION_READY)
        and not (CheckBoxEmulationKKT.Checked)) or CheckBoxEmulMistOISM.Checked then
    begin
      ErrorCode := fptr.errorCode;
      errorDescr:=fptr.errorDescription;
      ResultCodeCheckOnKKTEdit.Text:=IntToStr(ErrorCode);
      ResultDescrCheckOnKKTEdit.Text:=errorDescr;

      ButtonDissconnectFromKKTClick(self);
      exit;
    end;*}
    validationResult := fptr.getParamInt(fptr.LIBFPTR_PARAM_MARKING_CODE_ONLINE_VALIDATION_RESULT);

    actionType := 'acceptMarkingCode';
    fptr.acceptMarkingCode;

    ErrorCode := fptr.errorCode;
    errorDescr:=fptr.errorDescription;

    LogMessage('validationResult = ' + IntToStr(validationResult));

    ButtonDissconnectFromKKTClick(self);

    if CheckBoxEmulationKKT.Checked and (errorCode <> 0) then begin
      errorCode:=0;
      validationResult:=15;
    end;

    ResultCodeCheckOnKKTEdit.Text := IntToStr(errorCode);
    ResultDescrCheckOnKKTEdit.Text := errorDescr;
    EditValidationResult.Text:=IntToStr(validationResult);

    if (errorCode = 0) or not (CheckBoxEmulationKKT.Checked) then
      LogMessage('Проверка марки выполнена успешно')
    else
      LogMessage('Ошибка проверки марки');
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

procedure TCheckMarksForm.ButtonAddToTableClick(Sender: TObject);
var
  markResult: TMarkResult;
  markBase64: string;
  errorCode: Integer;
  validationResult: Integer;
  i: Integer;
  foundPosition: Integer;
begin
  // Получаем данные из полей формы
  //mark := StringReplace(EditCurrentMark.Text, '\u001d', #29, [rfReplaceAll, rfIgnoreCase]);
  markBase64 := EditCurrentMarkBase64.Text;

  if (ResultCodeCheckOnKKTEdit.Text = '') or ((EditCodeResultCheckPermit.Text = '') and CheckRRVkl.Checked) then begin
    LogMessage('ОШИБКА: Проверка марки ещё не производилась');
    Exit;
  end;

  errorCode := StrToIntDef(ResultCodeCheckOnKKTEdit.Text, -1);
  validationResult := StrToIntDef(EditValidationResult.Text, 0);

  if markBase64 = '' then
  begin
    LogMessage('ОШИБКА: Не указана марка для добавления в таблицу');
    Exit;
  end;
  
  // Находим позицию марки в исходном массиве
  foundPosition := 0;
  for i := 0 to High(FInputMarks) do
  begin
    if FInputMarks[i].MarkCodeBase64 = markBase64 then
    begin
      foundPosition := FInputMarks[i].Position;
      Break;
    end;
  end;
  
  // СОХРАНЯЕМ РЕЗУЛЬТАТ В КЭШ
  markResult.Position := foundPosition;
  markResult.MarkCodeBase64 := EditCurrentMarkBase64.Text;  // Сохраняем Base64 версию
  markResult.CheckTime := Now;
  markResult.KKTCheckCode := errorCode;
  markResult.KKTCheckDescription := StringReplace(ResultDescrCheckOnKKTEdit.Text, ',', '',  [rfReplaceAll]);
  markResult.ValidationResult := validationResult;
  markResult.PermitCheckCode := StrToIntDef(EditCodeResultCheckPermit.Text, 0);
  markResult.PermitCheckDescription :=  StringReplace(EditDescrResultPerimtCheck.Text, ',', '',  [rfReplaceAll]);
  markResult.UUID := EditUUID.Text;
  markResult.TimeStamp := EditTimeStamp.Text;
  markResult.Inst := EditInst.Text;
  markResult.Ver := EditVer.Text;

  // Добавляем или обновляем результат в кэше
  AddMarkToCache(markResult);

  // Обновляем таблицу результатов - перезаполняем полностью
  MemoResult.Clear;
  MemoResult.Lines.Add('Position;MarkCode;KKTCheckCode;KKTCheckDescription;ValidationResult;PermitCheckCode;PermitCheckDescription;UUID;TimeStamp;Inst;Ver');
  
  // Добавляем все результаты из кэша
  for i := 0 to High(FCheckCache) do
  begin
    MemoResult.Lines.Add(MarkResultToStr(FCheckCache[i]));
  end;

  LogMessage('Размер кэша: ' + IntToStr(Length(FCheckCache)) + ' марок');  
end;

procedure TCheckMarksForm.ButtonBeginLogClick(Sender: TObject);
begin
 FStopLog:=false;
end;

function TCheckMarksForm.MarkResultToStr(R: TMarkResult):string;
begin
  Result:=Format('%d;%s;%d;%s;%d;%d;%s;%s;%s;%s;%s', [
        R.Position,
        R.MarkCodeBase64,
        R.KKTCheckCode,
        R.KKTCheckDescription,
        R.ValidationResult,
        R.PermitCheckCode,
        R.PermitCheckDescription,
        R.UUID,
        R.TimeStamp,
        R.Inst,
        R.Ver
      ]);
end;

// Сохранить результаты проверки в CSV файл
procedure TCheckMarksForm.ButtonSaveResultsClick(Sender: TObject);
begin
  try
    if Length(FCheckCache) = 0 then
    begin
      LogMessage('ОШИБКА: Нет проверенных марок для сохранения.');
      Exit;
    end;

    LogMessage('=== СОХРАНЕНИЕ РЕЗУЛЬТАТОВ ===');
    LogMessage('Всего марок: ' + IntToStr(Length(FInputMarks)));
    LogMessage('Проверено марок: ' + IntToStr(Length(FCheckCache)));

    // Проверяем, все ли марки проверены
    if Length(FCheckCache) < Length(FInputMarks) then
    begin
      LogMessage('ПРЕДУПРЕЖДЕНИЕ: Проверены не все марки!');
      LogMessage('Непроверено: ' + IntToStr(Length(FInputMarks) - Length(FCheckCache)));
    end;

    // Сохраняем результаты в CSV
    if SaveResultsToCSV then
    begin
      LogMessage('✓ Результаты сохранены в файл: ' + CSV_OUTPUT_RESULTS);
      LogMessage('✓ Файл готов для чтения 1С');
    end
    else
    begin
      LogMessage('ОШИБКА: Не удалось сохранить результаты');
    end;

  except
    on E: Exception do
    begin
      LogMessage('ОШИБКА сохранения: ' + E.Message);
    end;
  end;
end;

procedure TCheckMarksForm.ButtonStopLogClick(Sender: TObject);
begin
  FStopLog:=true;
end;

// Команда: начать обработку чека
procedure TCheckMarksForm.ButtonReceiptProcessClick(Sender: TObject);
var
 MarkForCheck:string;
 WasCheckingAny:boolean;
begin
  //TimerForCommandsFrom1c.Enabled:=false; //вроучную будем проверять команды
  WasCheckingAny:=false;
  LogMessage('=== КНОПКА: ЗАПУСК ЦИКЛА ПРОВЕРКИ МАРОК ===');
  TimerCheckMarks.Enabled:=false; //отключаем таймер, пока полностью не завершим проверку марок по одному циклу

  // Загружаем марки из CSV
  MarkForCheck:='';
  ButtonGetMarksForCheckClick(Self); //загружаем задания из 1с маркок для проверки

  ButtonGetNextMarkClick(self); //получем первое задания для проверки
  MarkForCheck:=EditCurrentMarkBase64.Text;

  if MarkForCheck <> '' then begin
    //CheckMarkOnKKTButtonClick(self); //запускаем провекру марки на ККТ
    //ButtonOpenShiftIfNeedClick(self);
  end;

  while MarkForCheck <> '' do begin
    WasCheckingAny:=true;
    //ButtonCheckStatusKKTClick(self);

    CheckMarkOnKKTButtonClick(self);
    if CheckRRVkl.Checked then //запускаем проверку марок по РР
      ButtonCheckPermitMarkClick(self);

    ButtonAddToTableClick(self); //запоминаем результаты проверки

    //TimerForCommandsFrom1c.OnTimer(self); //может от 1с придёт какая команда
    //if FClosingRecipt then break;  //выходим из цикла проверовк марок, если чек уже закрывается
    ////1с сама проверит оставшиеся марки

    ButtonGetNextMarkClick(self); //получем очередное задания для проверки
    MarkForCheck:=EditCurrentMarkBase64.Text;

    if FClosingRecipt then break; //выходим из цикла, если чек уже закрывается, не сработает, так как поток занят обработкой проверки марок и не смотрит, что приходит от 1с
  end;

  if WasCheckingAny then ButtonSaveResultsClick(self);

  if not FClosingRecipt then //если мы не в процессе закрытия чеки, то продолжим цикл
   TimerCheckMarks.Enabled:=true; //через сколько то секунду запускам очередной цикл провекри марок
  //TimerForCommandsFrom1c.Enabled:=true;
end;

procedure TCheckMarksForm.ButtonReceiptClosingClick(Sender: TObject);
begin
  LogMessage('=== КНОПКА: ЧЕК ЗАКРЫВАЕТСЯ ===');
  FClosingRecipt:=true; //не будем начинать новую проверку, так как чек закрывается, а срочно
  //доделываем текущую проверку и отключаемся от ККТ
end;

procedure TCheckMarksForm.ButtonRecieptWasClosedClick(Sender: TObject);
begin
  LogMessage('=== КНОПКА: ЧЕК ЗАКРЫТ ===');
  
  // Полная очистка всех данных
  ClearAllData();
  MemoMarks.Clear;
  MemoResult.Clear;
  EditCurrentMarkBase64.Text:='';
  EditCurrentMark.Text := '';
  EditCurrentMarkCodeIdent.Text := '';
  ClearCheckMarkResault;
  
  FClosingRecipt := False;

  if FileExists(CSV_OUTPUT_RESULTS) then
    try
      TFile.Delete(CSV_OUTPUT_RESULTS);
    except
    end;
  LogMessage('✓ Все данные очищены, готов к новому чеку');
end;

procedure TCheckMarksForm.ButtonCancelReciptClick(Sender: TObject);
begin
  LogMessage('=== КНОПКА: ОТМЕНИТЬ ЧЕК ===');
  TimerCheckMarks.Enabled:=false;
  // Отменяем текущую проверку марки, если она идет
  try
    ButtonConnectToKKTClick(self);
    fptr.cancelMarkingCodeValidation;
    fptr.clearMarkingCodeValidationResult;
    LogMessage('✓ Проверка марки отменена');
  except
    on E: Exception do
      LogMessage('Ошибка отмены проверки: ' + E.Message);
  end;
  ButtonDissconnectFromKKTClick(self);

  // Очищаем все данные
  ButtonRecieptWasClosedClick(self);
end;

// Функция проверки марки по разрешительному режиму через HTTP
// ВАЖНО: MarkCode должен быть в формате Base64!
function TCheckMarksForm.CheckMarkByPermitMode(const MarkCode: string; const IPServer: string; Port: Integer): TMarkResult;
var
  HTTPClient: THTTPClient;
  RequestJSON, ResponseJSON: TJSONObject;
  PositionsArray: TJSONArray;
  PositionObj: TJSONObject;
  CodesArray: TJSONArray;
  RequestBody, ResponseBody: string;
  Response: IHTTPResponse;
  URL: string;
  TruemarkResponse: TJSONObject;
  JSONValue: TJSONValue;
  CleanJSON: string;
  ReqIdValue: string;
  PosInst: Integer;
begin
  // Инициализируем результат значениями по умолчанию
  Result := Default(TMarkResult);
  Result.PermitCheckCode := -1;
  Result.PermitCheckDescription := 'Ошибка: не удалось выполнить запрос';
  
  HTTPClient := THTTPClient.Create;
  try
    HTTPClient.ConnectionTimeout := 10000; // 10 секунд
    HTTPClient.ResponseTimeout := 10000;
    
    // Формируем JSON запрос
    RequestJSON := TJSONObject.Create;
    try
      RequestJSON.AddPair('action', 'check');
      RequestJSON.AddPair('type', 'receipt');
      //RequestJSON.AddPair('shift', '0456010012345654');  // TODO: получать реальный номер смены
      
      // Массив позиций
      PositionsArray := TJSONArray.Create;
      PositionObj := TJSONObject.Create;
      
      // Добавляем organization с inn
      var OrgObj := TJSONObject.Create;
      OrgObj.AddPair('inn', EditINNFirmy.Text);  // TODO: получать реальный ИНН
      PositionObj.AddPair('organization', OrgObj);
      
      // Массив кодов маркировки (марка уже должна быть в Base64!)
      CodesArray := TJSONArray.Create;
      CodesArray.Add(MarkCode);
      
      PositionObj.AddPair('marking_codes', CodesArray);
      PositionsArray.Add(PositionObj);
      
      RequestJSON.AddPair('positions', PositionsArray);
      
      RequestBody := RequestJSON.ToString;
      
      LogMessage('РР: Отправка запроса к ' + IPServer + ':' + IntToStr(Port));
      LogMessage('РР: Тело запроса: ' + RequestBody);
      
      // Формируем URL
      URL := Format('http://%s:%d/document', [IPServer, Port]);
      
      // Отправляем POST запрос
      try
        HTTPClient.ContentType := 'application/json';
        Response := HTTPClient.Post(URL, TStringStream.Create(RequestBody, TEncoding.UTF8));
        
        if Response.StatusCode = 200 then
        begin
          ResponseBody := Response.ContentAsString(TEncoding.UTF8);
          LogMessage('РР: Получен ответ: ' + ResponseBody);
          
          // Очищаем JSON от специальных символов (как в 1С)
          CleanJSON := StringReplace(ResponseBody, '"fmu-api-offline"', '"fmuApiOffline"', [rfReplaceAll]);
          CleanJSON := StringReplace(CleanJSON, '"fmu-api-localModul"', '"fmuApiLocalModul"', [rfReplaceAll]);
          
          // Парсим JSON ответ
          LogMessage('РР: Парсим JSON, длина: ' + IntToStr(Length(CleanJSON)));
          JSONValue := TJSONObject.ParseJSONValue(CleanJSON);
          try
            if Assigned(JSONValue) then
            begin
              LogMessage('РР: JSONValue присвоен, тип: ' + JSONValue.ClassName);
              if JSONValue is TJSONObject then
              begin
                LogMessage('РР: JSONValue является TJSONObject - парсим дальше');
                ResponseJSON := JSONValue as TJSONObject;
                
                // Получаем Code (код FMU) - основной код из корня JSON
                if ResponseJSON.TryGetValue('code', JSONValue) then
                begin
                  Result.PermitCheckCode := StrToIntDef(JSONValue.Value, -1);
                  LogMessage('РР: Основной код FMU: ' + IntToStr(Result.PermitCheckCode));
                end;
                
                // Получаем Error (описание ошибки FMU) - основное описание из корня JSON
                if ResponseJSON.TryGetValue('error', JSONValue) then
                begin
                  Result.PermitCheckDescription := JSONValue.Value;
                  LogMessage('РР: Основное описание FMU: ' + Result.PermitCheckDescription);
                end;
                
                // Получаем данные из truemark_response
                if ResponseJSON.TryGetValue('truemark_response', JSONValue) and (JSONValue is TJSONObject) then
                begin
                  TruemarkResponse := JSONValue as TJSONObject;
                  
                  // code - код от ЧЗ МАК (перезаписывает только если основной код = 0)
                  if TruemarkResponse.TryGetValue('code', JSONValue) then
                  begin
                    var TruemarkCode := StrToIntDef(JSONValue.Value, Result.PermitCheckCode);
                    if Result.PermitCheckCode = 0 then
                    begin
                      LogMessage('РР: Код ЧЗ МАК: ' + IntToStr(TruemarkCode) + ' (перезаписывает основной код ' + IntToStr(Result.PermitCheckCode) + ')');
                      Result.PermitCheckCode := TruemarkCode;
                    end
                    else
                    begin
                      LogMessage('РР: Код ЧЗ МАК: ' + IntToStr(TruemarkCode) + ' (НЕ перезаписывает основной код ' + IntToStr(Result.PermitCheckCode) + ' - основной код не равен 0)');
                    end;
                  end;
                  
                  // description - перезаписывает только если основной код = 0
                  if TruemarkResponse.TryGetValue('description', JSONValue) then
                  begin
                    if Result.PermitCheckCode = 0 then
                    begin
                      LogMessage('РР: Описание ЧЗ МАК: ' + JSONValue.Value + ' (перезаписывает основное описание "' + Result.PermitCheckDescription + '")');
                      Result.PermitCheckDescription := JSONValue.Value;
                    end
                    else
                    begin
                      LogMessage('РР: Описание ЧЗ МАК: ' + JSONValue.Value + ' (НЕ перезаписывает основное описание "' + Result.PermitCheckDescription + '" - основной код не равен 0)');
                    end;
                  end;
                  
                  // reqId (UUID)
                  if TruemarkResponse.TryGetValue('reqId', JSONValue) then
                  begin
                    ReqIdValue := JSONValue.Value;
                    // Удаляем &Inst из UUID, если есть
                    PosInst := Pos('&Inst', ReqIdValue);
                    if PosInst > 0 then
                      ReqIdValue := Copy(ReqIdValue, 1, PosInst - 1);
                    Result.UUID := ReqIdValue;
                  end;
                  
                  // reqTimestamp
                  if TruemarkResponse.TryGetValue('reqTimestamp', JSONValue) then
                    Result.TimeStamp := JSONValue.Value;
                  
                  // inst
                  if TruemarkResponse.TryGetValue('inst', JSONValue) then
                    Result.Inst := JSONValue.Value;
                  
                  // version
                  if TruemarkResponse.TryGetValue('version', JSONValue) then
                    Result.Ver := JSONValue.Value;
                end;
                
                LogMessage('РР: Code=' + IntToStr(Result.PermitCheckCode) + ', Descr=' + Result.PermitCheckDescription);
                LogMessage('РР: UUID=' + Result.UUID);
              end
              else
              begin
                LogMessage('РР: ОШИБКА - JSONValue не является TJSONObject, тип: ' + JSONValue.ClassName);
                Result.PermitCheckDescription := 'Ошибка: JSON не является объектом, тип: ' + JSONValue.ClassName;
              end;
            end
            else
            begin
              LogMessage('РР: ОШИБКА - JSONValue не присвоен');
              Result.PermitCheckDescription := 'Ошибка: не удалось распарсить JSON';
            end;
          except
            on E: Exception do
            begin
              Result.PermitCheckDescription := 'Ошибка парсинга JSON: ' + E.Message;
              LogMessage('РР: ' + Result.PermitCheckDescription);
            end;
          end;
          JSONValue.Free;
        end
        else
        begin
          Result.PermitCheckDescription := Format('HTTP ошибка: %d %s', [Response.StatusCode, Response.StatusText]);
          LogMessage('РР: ' + Result.PermitCheckDescription);
        end;
        
      except
        on E: Exception do
        begin
          Result.PermitCheckDescription := 'Исключение при HTTP запросе: ' + E.Message;
          LogMessage('РР: ' + Result.PermitCheckDescription);
        end;
      end;
      
    finally
      RequestJSON.Free;
    end;
    
  finally
    HTTPClient.Free;
  end;
end;

procedure TCheckMarksForm.ButtonCheckPermitMarkClick(Sender: TObject);
var
  MarkCodeBase64: string;
  IPServer: string;
  Port: Integer;
  PermitResult: TMarkResult;
begin
  LogMessage('=== ПРОВЕРКА МАРКИ ПО РАЗРЕШИТЕЛЬНОМУ РЕЖИМУ ===');
  
  // Получаем параметры - ВАЖНО: для РР нужна марка в Base64!
  MarkCodeBase64 := EditCurrentMarkBase64.Text;
  IPServer := Trim(EditIpRR.Text);
  Port := StrToIntDef(Trim(EditPortRR.Text), 2578);
  
  if MarkCodeBase64 = '' then
  begin
    LogMessage('РР: ОШИБКА - не указана марка для проверки');
    Exit;
  end;
  
  if IPServer = '' then
  begin
    LogMessage('РР: ОШИБКА - не указан IP сервера РР');
    Exit;
  end;
  
  // Выполняем проверку (передаем Base64 версию марки)
  PermitResult := CheckMarkByPermitMode(MarkCodeBase64, IPServer, Port);
  
  // Заполняем поля формы результатами
  EditCodeResultCheckPermit.Text := IntToStr(PermitResult.PermitCheckCode);
  EditDescrResultPerimtCheck.Text := PermitResult.PermitCheckDescription;
  EditUUID.Text := PermitResult.UUID;
  EditTimeStamp.Text := PermitResult.TimeStamp;
  EditInst.Text := PermitResult.Inst;
  EditVer.Text := PermitResult.Ver;
  
  if PermitResult.PermitCheckCode = 0 then
    LogMessage('РР: ✓ Проверка завершена успешно')
  else
    LogMessage('РР: ✗ Проверка завершена с ошибкой');
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
  NomComPorta:integer;
  PauseTormozovKKT, CodeMist:integer;
begin
  LogMessage('=== КНОПКА: ПОДКЛЮЧИТЬСЯ К ККТ ===');
  isOpened := fptr.isOpened;
  if CheckBoxEmulationKKT.Checked then begin
   if (POS('not connected', LabelConnectionWithKKT.Caption) = 0) and
        (POS('connected', LabelConnectionWithKKT.Caption) > 0)
   then isOpened:=true;
  end;
  if isOpened then
    textOfConnection:='connected'
  else begin
    NomComPorta:=StrToIntDef(EditComPortKKT.Text, 0);
    if NomComPorta > 0 then begin
      fptr.setSingleSetting(fptr.LIBFPTR_SETTING_PORT, fptr.LIBFPTR_PORT_COM);
      fptr.setSingleSetting(fptr.LIBFPTR_SETTING_COM_FILE, NomComPorta);
      fptr.setSingleSetting(fptr.LIBFPTR_SETTING_BAUDRATE, fptr.LIBFPTR_PORT_BR_115200);
    end
    else fptr.setSingleSetting(fptr.LIBFPTR_SETTING_PORT, fptr.LIBFPTR_PORT_USB);
    fptr.setSingleSetting(fptr.LIBFPTR_SETTING_TIME_ZONE, ComboBoxTimeZone.ItemIndex + 1);
    fptr.applySingleSettings;
    fptr.open;
    isOpened := fptr.isOpened;
    if CheckBoxEmulationKKT.Checked and CheckBoxEmulationTormoz.Checked then begin
      Val(EditPauseTormozaKKTEmul.Text, PauseTormozovKKT, CodeMist);
      if CodeMist <> 0 then PauseTormozovKKT:=60; //по умолчанию 60 секунд
      sleep(PauseTormozovKKT*1000);
    end;
  end;
  if CheckBoxEmulationKKT.Checked then begin
    isOpened:=true;
    textOfConnection:='connected - эмуляция ККТ';
  end;
  if not(isOpened) then
    textOfConnection:=fptr.errorDescription;
  if CheckBoxEmulationKKT.Checked then
    LabelConnectionWithKKT.Caption:=textOfConnection;
  if isOpened then LogMessage('подключились к ККТ');
  LogMessage('=== КНОПКА: ПОДКЛЮЧИТЬСЯ К ККТ - END ===');
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
  if not DonCloseConnectionWithKKTCheckBox.Checked then begin
    fptr.close;
    LogMessage('отключились от ККТ');
    LabelConnectionWithKKT.Caption:='disconnected';
  end else begin
    LogMessage('отключились от ККТ - не отключаемся');
    //LabelConnectionWithKKT.Caption:='disconnected';
  end;
end;

procedure TCheckMarksForm.ButtonDestroyDiverKKTClick(Sender: TObject);
begin
  fptr := Unassigned;
  LabelInitDriverKKT.Caption:='не инициализирован';
end;

function TCheckMarksForm.MarkInputToStr(InputMark: TInputMark):string;
var s:string;
begin
   Result:=IntToStr(InputMark.Position);
   Result:=Result+';'+InputMark.MarkCodeBase64;
   Result:=Result+';'+InputMark.PlannedStatus;
end;

end.
