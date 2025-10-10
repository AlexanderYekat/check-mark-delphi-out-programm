unit check_marks;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, ComObj, System.JSON, System.IOUtils;

const
  DRIVER_NOT_INIT = 'не инициализирован';
  TEXT_SHIFT_OPENNED = 'открыта';
  TEXT_SHIFT_CLOSED = 'закрыта';
  TEXT_SHIFT_EXPIRED = 'истекла';

  RESULT_COMMAND_OK = 'OK';
  TYPE_OF_CHECK_SELL = 'sell';
  TYPE_OF_CHECK_RETURN = 'return';
  
  // Пути к папкам заданий
  TASKS_PATH_PENDING = 'c:\share\tasks\pending\';
  TASKS_PATH_PROCESSING = 'c:\share\tasks\processing\';
  TASKS_PATH_COMPLETED = 'c:\share\tasks\completed\';

  PLANNED_STATUS_OF_MARK_PIECE_SOLD = 'штучный товар, реализован';
  PLANNED_STATUS_OF_MARK_DRY_FOR_SALE = 'мерный товар, в стадии реализации';
  PLANNED_STATUS_OF_PIECE_RETURN = 'штучный товар, возвращен';
  PLANNED_STATUS_OF_DRY_RETURN = 'штучный товар, в стадии реализации';
  PLANNED_STATUS_OF_PIECE_FOR_SALE = 'штучный товар, в стадии реализации';
  PLANNED_STATUS_OF_DRY_SOLD = 'мерный товар, реализован';
  PLANNED_STATUS_OF_UNCHANGED = 'статус товара не изменился';

type
  // Структура для хранения результата проверки марки
  TMarkCheckResult = record
    MarkCode: string;
    CheckTime: TDateTime;
    Success: Boolean;
    ResultCode: Integer;
    ResultDescription: string;
    JSONResponse: string;
  end;

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
    procedure ButtonGetTasksClick(Sender: TObject);
    procedure ButtonGetNextTaskClick(Sender: TObject);
    procedure ButtonSaveResultTaskClick(Sender: TObject);
    procedure ButtonCreateNewSessionClick(Sender: TObject);
    procedure ButtonFinishSessionClick(Sender: TObject);
  private
    { Private declarations }
    fptr: OLEVariant;
    FMarkCheckCache: TArray<TMarkCheckResult>; // Кэш результатов проверки марок
    FSessionActive: Boolean; // Флаг активной сессии
    function CreateJSONAcceptOrDeclineOrCancel(ActionType: string): string;
    function RunProcessOnKKT(JSONRequest: string; var JSONResponse: string; var ErrorCode: Integer; var ErrorDescr: string): Boolean;
    function FindMarkInCache(const MarkCode: string; out Result: TMarkCheckResult): Boolean;
    procedure AddMarkToCache(const MarkResult: TMarkCheckResult);
    procedure ClearMarkCache;
  public
    { Public declarations }
  end;

var
  CheckMarksForm: TCheckMarksForm;

implementation

{$R *.dfm}

// === ФУНКЦИИ РАБОТЫ С КЭШЕМ МАРОК ===

// Поиск марки в кэше
function TCheckMarksForm.FindMarkInCache(const MarkCode: string; out Result: TMarkCheckResult): Boolean;
var
  i: Integer;
begin
  Result := Default(TMarkCheckResult);
  for i := 0 to High(FMarkCheckCache) do
  begin
    if FMarkCheckCache[i].MarkCode = MarkCode then
    begin
      Result := FMarkCheckCache[i];
      Exit(True);
    end;
  end;
  Exit(False);
end;

// Добавление результата проверки марки в кэш
procedure TCheckMarksForm.AddMarkToCache(const MarkResult: TMarkCheckResult);
begin
  SetLength(FMarkCheckCache, Length(FMarkCheckCache) + 1);
  FMarkCheckCache[High(FMarkCheckCache)] := MarkResult;
end;

// Очистка кэша марок
procedure TCheckMarksForm.ClearMarkCache;
begin
  SetLength(FMarkCheckCache, 0);
  FSessionActive := False;
end;

// === КОНЕЦ ФУНКЦИЙ РАБОТЫ С КЭШЕМ ===

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
    cachedResult: TMarkCheckResult;
    markResult: TMarkCheckResult;
begin
    // Очищаем результаты предыдущей проверки
    MemoJSONResultCheckOnKKT.Clear;
    ResultCodeCheckOnKKTEdit.Text := '0';
    ResultDescrCheckOnKKTEdit.Text := RESULT_COMMAND_OK;
    
    mark:=StringReplace(EditMark.Text, '\u001d', #29, [rfReplaceAll, rfIgnoreCase]);
    
    // ПРОВЕРЯЕМ КЭШ - если марка уже проверялась, берем результат из кэша
    if FSessionActive and FindMarkInCache(mark, cachedResult) then
    begin
      MemoJSONResultCheckOnKKT.Lines.Add('=== РЕЗУЛЬТАТ ИЗ КЭША ===');
      MemoJSONResultCheckOnKKT.Lines.Add('Марка уже проверялась ранее');
      MemoJSONResultCheckOnKKT.Lines.Add('Время проверки: ' + DateTimeToStr(cachedResult.CheckTime));
      MemoJSONResultCheckOnKKT.Lines.Add('');
      MemoJSONResultCheckOnKKT.Lines.Add(cachedResult.JSONResponse);
      ResultCodeCheckOnKKTEdit.Text := IntToStr(cachedResult.ResultCode);
      ResultDescrCheckOnKKTEdit.Text := cachedResult.ResultDescription;
      
      if cachedResult.Success then
        MemoJSONResultCheckOnKKT.Lines.Add('✓ Команда выполнена успешно (из кэша)')
      else
        MemoJSONResultCheckOnKKT.Lines.Add('✗ Ошибка выполнения команды (из кэша)');
        
      Exit;
    end;
    
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
    
    // СОХРАНЯЕМ РЕЗУЛЬТАТ В КЭШ
    if FSessionActive then
    begin
      markResult.MarkCode := mark;
      markResult.CheckTime := Now;
      markResult.Success := success;
      markResult.ResultCode := errorCode;
      markResult.ResultDescription := errorDescr;
      markResult.JSONResponse := jsonAnswer;
      AddMarkToCache(markResult);
      
      MemoJSONResultCheckOnKKT.Lines.Add('');
      MemoJSONResultCheckOnKKT.Lines.Add('✓ Результат сохранен в кэш');
      MemoJSONResultCheckOnKKT.Lines.Add('Размер кэша: ' + IntToStr(Length(FMarkCheckCache)) + ' марок');
    end;
end;

// Загрузка заданий из файловой системы
procedure TCheckMarksForm.ButtonGetTasksClick(Sender: TObject);
var
  pendingFiles: TArray<string>;
  processingFiles: TArray<string>;
  completedFiles: TArray<string>;
  filePath: string;
  fileContent: string;
  JSONValue: TJSONValue;
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  markingCodes: TJSONArray;
  sellOrReturn: string;
  taskId: string;
  i: Integer;
  totalTasks: Integer;
begin
  MemoTasks.Clear;
  MemoTasks.Lines.Add('=== ЗАГРУЗКА ЗАДАНИЙ ===');
  MemoTasks.Lines.Add('');
  
  totalTasks := 0;
  
  try
    // Создаем папки, если их нет
    if not TDirectory.Exists(TASKS_PATH_PENDING) then
      TDirectory.CreateDirectory(TASKS_PATH_PENDING);
    if not TDirectory.Exists(TASKS_PATH_PROCESSING) then
      TDirectory.CreateDirectory(TASKS_PATH_PROCESSING);
    if not TDirectory.Exists(TASKS_PATH_COMPLETED) then
      TDirectory.CreateDirectory(TASKS_PATH_COMPLETED);
    
    // === ЗАГРУЖАЕМ ЗАДАНИЯ ИЗ PENDING ===
    MemoTasks.Lines.Add('--- ОЖИДАЮЩИЕ ЗАДАНИЯ (PENDING) ---');
    pendingFiles := TDirectory.GetFiles(TASKS_PATH_PENDING, '*.json');
    
    if Length(pendingFiles) = 0 then
      MemoTasks.Lines.Add('Нет ожидающих заданий')
    else
    begin
      for filePath in pendingFiles do
      begin
        taskId := TPath.GetFileNameWithoutExtension(filePath);
        
        try
          fileContent := TFile.ReadAllText(filePath, TEncoding.UTF8);
          JSONValue := TJSONObject.ParseJSONValue(fileContent);
          
          if Assigned(JSONValue) and (JSONValue is TJSONObject) then
          begin
            JSONObj := JSONValue as TJSONObject;
            
            // Извлекаем sellOrReturn
            if JSONObj.TryGetValue<string>('sellOrReturn', sellOrReturn) then
            else
              sellOrReturn := 'sell';
            
            // Извлекаем массив маркировок
            if JSONObj.TryGetValue<TJSONArray>('markingCodes', markingCodes) then
            begin
              MemoTasks.Lines.Add('');
              MemoTasks.Lines.Add('Task ID: ' + taskId);
              MemoTasks.Lines.Add('Статус: PENDING');
              MemoTasks.Lines.Add('Операция: ' + sellOrReturn);
              MemoTasks.Lines.Add('Количество марок: ' + IntToStr(markingCodes.Count));
              
              // Показываем первые 3 марки
              for i := 0 to Min(2, markingCodes.Count - 1) do
              begin
                MemoTasks.Lines.Add('  Марка ' + IntToStr(i + 1) + ': ' + markingCodes.Items[i].Value);
              end;
              
              if markingCodes.Count > 3 then
                MemoTasks.Lines.Add('  ... и ещё ' + IntToStr(markingCodes.Count - 3) + ' марок');
              
              Inc(totalTasks);
            end;
            
            JSONValue.Free;
          end;
        except
          on E: Exception do
            MemoTasks.Lines.Add('Ошибка чтения файла ' + taskId + ': ' + E.Message);
        end;
      end;
    end;
    
    // === ЗАГРУЖАЕМ ЗАДАНИЯ ИЗ PROCESSING ===
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('--- ЗАДАНИЯ В ОБРАБОТКЕ (PROCESSING) ---');
    processingFiles := TDirectory.GetFiles(TASKS_PATH_PROCESSING, '*.json');
    
    if Length(processingFiles) = 0 then
      MemoTasks.Lines.Add('Нет заданий в обработке')
    else
    begin
      for filePath in processingFiles do
      begin
        taskId := TPath.GetFileNameWithoutExtension(filePath);
        
        try
          fileContent := TFile.ReadAllText(filePath, TEncoding.UTF8);
          JSONValue := TJSONObject.ParseJSONValue(fileContent);
          
          if Assigned(JSONValue) and (JSONValue is TJSONObject) then
          begin
            JSONObj := JSONValue as TJSONObject;
            
            if JSONObj.TryGetValue<string>('sellOrReturn', sellOrReturn) then
            else
              sellOrReturn := 'sell';
            
            if JSONObj.TryGetValue<TJSONArray>('markingCodes', markingCodes) then
            begin
              MemoTasks.Lines.Add('');
              MemoTasks.Lines.Add('Task ID: ' + taskId);
              MemoTasks.Lines.Add('Статус: PROCESSING');
              MemoTasks.Lines.Add('Операция: ' + sellOrReturn);
              MemoTasks.Lines.Add('Количество марок: ' + IntToStr(markingCodes.Count));
              
              Inc(totalTasks);
            end;
            
            JSONValue.Free;
          end;
        except
          on E: Exception do
            MemoTasks.Lines.Add('Ошибка чтения файла ' + taskId + ': ' + E.Message);
        end;
      end;
    end;
    
    // === СТАТИСТИКА ===
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('===================');
    MemoTasks.Lines.Add('ВСЕГО ЗАДАНИЙ: ' + IntToStr(totalTasks));
    MemoTasks.Lines.Add('Pending: ' + IntToStr(Length(pendingFiles)));
    MemoTasks.Lines.Add('Processing: ' + IntToStr(Length(processingFiles)));
    MemoTasks.Lines.Add('===================');
    
  except
    on E: Exception do
    begin
      MemoTasks.Lines.Add('');
      MemoTasks.Lines.Add('ОШИБКА ЗАГРУЗКИ ЗАДАНИЙ: ' + E.Message);
    end;
  end;
end;

// Создать новую сессию - скопировать все задания из PENDING в PROCESSING
procedure TCheckMarksForm.ButtonCreateNewSessionClick(Sender: TObject);
var
  pendingFiles: TArray<string>;
  completedFiles: TArray<string>;
  filePath: string;
  newFilePath: string;
  taskId: string;
  copiedCount: Integer;
begin
  try
    // Проверяем, что COMPLETED пуста
    if TDirectory.Exists(TASKS_PATH_COMPLETED) then
    begin
      completedFiles := TDirectory.GetFiles(TASKS_PATH_COMPLETED, '*.json');
      if Length(completedFiles) > 0 then
      begin
        ShowMessage('Сессия не может быть начата!' + #13#10 + 
                    'В папке COMPLETED осталось ' + IntToStr(Length(completedFiles)) + ' файлов.' + #13#10 +
                    'Клиент 1С должен сначала забрать результаты.');
        Exit;
      end;
    end;
    
    // Проверяем, что PROCESSING пуста
    if TDirectory.Exists(TASKS_PATH_PROCESSING) then
    begin
      if Length(TDirectory.GetFiles(TASKS_PATH_PROCESSING, '*.json')) > 0 then
      begin
        ShowMessage('В папке PROCESSING уже есть задания!' + #13#10 + 
                    'Завершите текущую сессию перед началом новой.');
        Exit;
      end;
    end;
    
    // Создаем папки, если их нет
    if not TDirectory.Exists(TASKS_PATH_PENDING) then
      TDirectory.CreateDirectory(TASKS_PATH_PENDING);
    if not TDirectory.Exists(TASKS_PATH_PROCESSING) then
      TDirectory.CreateDirectory(TASKS_PATH_PROCESSING);
    
    // Копируем все файлы из PENDING в PROCESSING
    pendingFiles := TDirectory.GetFiles(TASKS_PATH_PENDING, '*.json');
    
    if Length(pendingFiles) = 0 then
    begin
      ShowMessage('Нет заданий в папке PENDING');
      Exit;
    end;
    
    copiedCount := 0;
    for filePath in pendingFiles do
    begin
      taskId := TPath.GetFileNameWithoutExtension(filePath);
      newFilePath := TASKS_PATH_PROCESSING + taskId + '.json';
      TFile.Copy(filePath, newFilePath, True);
      Inc(copiedCount);
    end;
    
    // Очищаем кэш и устанавливаем флаг активной сессии
    ClearMarkCache;
    FSessionActive := True;
    
    MemoTasks.Clear;
    MemoTasks.Lines.Add('=== НОВАЯ СЕССИЯ СОЗДАНА ===');
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('Скопировано заданий: ' + IntToStr(copiedCount));
    MemoTasks.Lines.Add('Из: ' + TASKS_PATH_PENDING);
    MemoTasks.Lines.Add('В: ' + TASKS_PATH_PROCESSING);
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('Статус сессии: АКТИВНА');
    MemoTasks.Lines.Add('Кэш марок: ОЧИЩЕН');
    MemoTasks.Lines.Add('=========================');
    
    ShowMessage('Сессия начата!' + #13#10 + 'Заданий к обработке: ' + IntToStr(copiedCount));
    
  except
    on E: Exception do
    begin
      ShowMessage('Ошибка создания сессии: ' + E.Message);
    end;
  end;
end;

// Получить следующее задание из очереди PROCESSING
procedure TCheckMarksForm.ButtonGetNextTaskClick(Sender: TObject);
var
  processingFiles: TArray<string>;
  firstFile: string;
  taskId: string;
  fileContent: string;
  JSONValue: TJSONValue;
  JSONObj: TJSONObject;
  markingCodes: TJSONArray;
  sellOrReturn: string;
  i: Integer;
begin
  MemoCurrentTask.Clear;
  EditCurrentIDOfTask.Text := '';
  MemoAllMarksOfSession.Clear;
  
  try
    // Проверяем наличие заданий в processing
    if not TDirectory.Exists(TASKS_PATH_PROCESSING) then
    begin
      MemoCurrentTask.Lines.Add('Папка PROCESSING не найдена');
      Exit;
    end;
    
    processingFiles := TDirectory.GetFiles(TASKS_PATH_PROCESSING, '*.json');
    
    if Length(processingFiles) = 0 then
    begin
      MemoCurrentTask.Lines.Add('Нет заданий в PROCESSING');
      MemoCurrentTask.Lines.Add('Создайте новую сессию (кнопка "Создать новую сессию")');
      Exit;
    end;
    
    // Берем первый файл
    firstFile := processingFiles[0];
    taskId := TPath.GetFileNameWithoutExtension(firstFile);
    
    // Читаем содержимое
    fileContent := TFile.ReadAllText(firstFile, TEncoding.UTF8);
    JSONValue := TJSONObject.ParseJSONValue(fileContent);
    
    if not Assigned(JSONValue) or not (JSONValue is TJSONObject) then
    begin
      MemoCurrentTask.Lines.Add('Ошибка парсинга JSON задания');
      Exit;
    end;
    
    try
      JSONObj := JSONValue as TJSONObject;
      
      // Извлекаем данные
      if not JSONObj.TryGetValue<string>('sellOrReturn', sellOrReturn) then
        sellOrReturn := 'sell';
      
      if not JSONObj.TryGetValue<TJSONArray>('markingCodes', markingCodes) then
      begin
        MemoCurrentTask.Lines.Add('Ошибка: нет маркировок в задании');
        Exit;
      end;
      
      // Отображаем информацию о задании
      MemoCurrentTask.Lines.Add('=== ТЕКУЩЕЕ ЗАДАНИЕ ===');
      MemoCurrentTask.Lines.Add('');
      MemoCurrentTask.Lines.Add('Task ID: ' + taskId);
      MemoCurrentTask.Lines.Add('Статус: PROCESSING');
      MemoCurrentTask.Lines.Add('Операция: ' + sellOrReturn);
      MemoCurrentTask.Lines.Add('Количество марок: ' + IntToStr(markingCodes.Count));
      MemoCurrentTask.Lines.Add('');
      MemoCurrentTask.Lines.Add('--- СПИСОК МАРОК ---');
      
      // Сохраняем ID задания
      EditCurrentIDOfTask.Text := taskId;
      
      // Устанавливаем тип операции
      if sellOrReturn = 'sell' then
        EditSellOrReturn.Text := 'sell'
      else if sellOrReturn = 'return' then
        EditSellOrReturn.Text := 'return';
      
      // Отображаем все марки
      MemoAllMarksOfSession.Clear;
      for i := 0 to markingCodes.Count - 1 do
      begin
        MemoCurrentTask.Lines.Add(IntToStr(i + 1) + '. ' + markingCodes.Items[i].Value);
        MemoAllMarksOfSession.Lines.Add(markingCodes.Items[i].Value);
      end;
      
      MemoCurrentTask.Lines.Add('');
      MemoCurrentTask.Lines.Add('======================');
      MemoCurrentTask.Lines.Add('Задание готово к обработке');
      
    finally
      JSONValue.Free;
    end;
    
  except
    on E: Exception do
    begin
      MemoCurrentTask.Lines.Add('ОШИБКА: ' + E.Message);
    end;
  end;
end;

// Сохранить результат выполнения задания
procedure TCheckMarksForm.ButtonSaveResultTaskClick(Sender: TObject);
var
  taskId: string;
  processingFilePath: string;
  completedFilePath: string;
  resultJSON: TJSONObject;
  dataJSON: TJSONObject;
  resultDataJSON: TJSONObject;
  resultString: string;
  success: Boolean;
begin
  taskId := Trim(EditCurrentIDOfTask.Text);
  
  if taskId = '' then
  begin
    ShowMessage('Не указан ID задания');
    Exit;
  end;
  
  try
    processingFilePath := TASKS_PATH_PROCESSING + taskId + '.json';
    
    if not TFile.Exists(processingFilePath) then
    begin
      ShowMessage('Файл задания не найден в папке processing');
      Exit;
    end;
    
    // Определяем успешность на основе кода результата
    success := (EditCodeResultOfTask.Text = '0') or (EditCodeResultOfTask.Text = '');
    
    // Формируем JSON результата
    resultJSON := TJSONObject.Create;
    try
      resultJSON.AddPair('success', TJSONBool.Create(success));
      
      // Создаем объект data
      dataJSON := TJSONObject.Create;
      dataJSON.AddPair('status', 'completed');
      
      // Создаем объект result с детальной информацией
      resultDataJSON := TJSONObject.Create;
      resultDataJSON.AddPair('success', TJSONBool.Create(success));
      resultDataJSON.AddPair('resultCode', EditCodeResultOfTask.Text);
      resultDataJSON.AddPair('resultDescription', EditDescrResultOfTask.Text);
      
      // Добавляем JSON ответ от ККТ, если он есть
      if MemoResultJSONTask.Lines.Count > 0 then
        resultDataJSON.AddPair('kktResponse', MemoResultJSONTask.Text);
      
      dataJSON.AddPair('result', resultDataJSON);
      resultJSON.AddPair('data', dataJSON);
      
      resultString := resultJSON.ToString;
      
      // Создаем папку completed, если её нет
      if not TDirectory.Exists(TASKS_PATH_COMPLETED) then
        TDirectory.CreateDirectory(TASKS_PATH_COMPLETED);
      
      // Сохраняем результат в файл
      completedFilePath := TASKS_PATH_COMPLETED + taskId + '.json';
      TFile.WriteAllText(completedFilePath, resultString, TEncoding.UTF8);
      
      // Удаляем файл из processing
      TFile.Delete(processingFilePath);
      
      // Очищаем поля
      EditCurrentIDOfTask.Text := '';
      MemoCurrentTask.Clear;
      MemoAllMarksOfSession.Clear;
      MemoResultJSONTask.Clear;
      EditCodeResultOfTask.Text := '';
      EditDescrResultOfTask.Text := '';
      
      MemoCurrentTask.Lines.Add('======================');
      MemoCurrentTask.Lines.Add('Результат сохранен!');
      MemoCurrentTask.Lines.Add('Task ID: ' + taskId);
      MemoCurrentTask.Lines.Add('Файл: ' + completedFilePath);
      MemoCurrentTask.Lines.Add('======================');
      
    finally
      resultJSON.Free;
    end;
    
  except
    on E: Exception do
    begin
      ShowMessage('Ошибка сохранения результата: ' + E.Message);
    end;
  end;
end;

// Завершить сессию - удалить файлы из PENDING и очистить память
procedure TCheckMarksForm.ButtonFinishSessionClick(Sender: TObject);
var
  pendingFiles: TArray<string>;
  processingFiles: TArray<string>;
  filePath: string;
  deletedPending: Integer;
  remainingProcessing: Integer;
  cacheSize: Integer;
begin
  try
    deletedPending := 0;
    remainingProcessing := 0;
    cacheSize := Length(FMarkCheckCache);
    
    MemoTasks.Clear;
    MemoTasks.Lines.Add('=== ЗАВЕРШЕНИЕ СЕССИИ ===');
    MemoTasks.Lines.Add('');
    
    // Проверяем, остались ли задания в PROCESSING
    if TDirectory.Exists(TASKS_PATH_PROCESSING) then
    begin
      processingFiles := TDirectory.GetFiles(TASKS_PATH_PROCESSING, '*.json');
      remainingProcessing := Length(processingFiles);
      
      if remainingProcessing > 0 then
      begin
        MemoTasks.Lines.Add('ВНИМАНИЕ! В папке PROCESSING осталось ' + IntToStr(remainingProcessing) + ' заданий!');
        MemoTasks.Lines.Add('Завершите все задания перед завершением сессии.');
        MemoTasks.Lines.Add('');
        
        if MessageDlg('В PROCESSING осталось ' + IntToStr(remainingProcessing) + ' заданий.' + #13#10 +
                      'Все равно завершить сессию?', mtWarning, [mbYes, mbNo], 0) <> mrYes then
        begin
          Exit;
        end;
        
        // Удаляем оставшиеся файлы из PROCESSING
        for filePath in processingFiles do
          TFile.Delete(filePath);
          
        MemoTasks.Lines.Add('Удалено файлов из PROCESSING: ' + IntToStr(remainingProcessing));
      end
      else
      begin
        MemoTasks.Lines.Add('✓ Все задания из PROCESSING выполнены');
      end;
    end;
    
    // Удаляем все файлы из PENDING
    if TDirectory.Exists(TASKS_PATH_PENDING) then
    begin
      pendingFiles := TDirectory.GetFiles(TASKS_PATH_PENDING, '*.json');
      
      for filePath in pendingFiles do
      begin
        TFile.Delete(filePath);
        Inc(deletedPending);
      end;
      
      if deletedPending > 0 then
        MemoTasks.Lines.Add('Удалено файлов из PENDING: ' + IntToStr(deletedPending))
      else
        MemoTasks.Lines.Add('✓ Папка PENDING уже пуста');
    end;
    
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('--- ОЧИСТКА ПАМЯТИ ---');
    MemoTasks.Lines.Add('Размер кэша марок до очистки: ' + IntToStr(cacheSize));
    
    // Очищаем кэш марок и завершаем сессию
    ClearMarkCache;
    
    MemoTasks.Lines.Add('✓ Кэш марок очищен');
    MemoTasks.Lines.Add('✓ Флаг сессии сброшен');
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('=== СЕССИЯ ЗАВЕРШЕНА ===');
    MemoTasks.Lines.Add('');
    MemoTasks.Lines.Add('Для начала новой сессии:');
    MemoTasks.Lines.Add('1. Клиент 1С должен забрать результаты из COMPLETED');
    MemoTasks.Lines.Add('2. Нажмите "Создать новую сессию"');
    
    // Очищаем поля текущего задания
    EditCurrentIDOfTask.Text := '';
    MemoCurrentTask.Clear;
    MemoAllMarksOfSession.Clear;
    
    ShowMessage('Сессия завершена!' + #13#10 + 
                'Удалено из PENDING: ' + IntToStr(deletedPending) + #13#10 +
                'Кэш марок очищен');
    
  except
    on E: Exception do
    begin
      ShowMessage('Ошибка завершения сессии: ' + E.Message);
    end;
  end;
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
