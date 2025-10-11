object CheckMarksForm: TCheckMarksForm
  Left = 0
  Top = 0
  Caption = 'CheckMarksForm'
  ClientHeight = 590
  ClientWidth = 1141
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object LabelCaptionOfStatusShift: TLabel
    Left = 556
    Top = 271
    Width = 79
    Height = 15
    Caption = #1057#1090#1072#1090#1091#1089' '#1089#1084#1077#1085#1099':'
  end
  object LabelStatusOfShift: TLabel
    Left = 556
    Top = 292
    Width = 81
    Height = 15
    Caption = 'not indefenned'
  end
  object LabelInitDriverKKT: TLabel
    Left = 559
    Top = 172
    Width = 116
    Height = 15
    Caption = #1085#1077' '#1080#1085#1080#1094#1080#1072#1083#1080#1079#1080#1088#1086#1074#1072#1085
  end
  object LabelConnectionWithKKT: TLabel
    Left = 560
    Top = 203
    Width = 77
    Height = 15
    Caption = 'not connected'
  end
  object LabelResultCommandDescr: TLabel
    Left = 42
    Top = 568
    Width = 16
    Height = 15
    Caption = 'OK'
  end
  object LabelResultCommandCode: TLabel
    Left = 42
    Top = 547
    Width = 6
    Height = 15
    Caption = '0'
  end
  object LabelCaptionResultCommans: TLabel
    Left = 42
    Top = 526
    Width = 181
    Height = 15
    Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090#1099' '#1074#1099#1087#1086#1083#1085#1077#1085#1080#1103' '#1082#1086#1084#1072#1085#1076':'
  end
  object LabelCaptionResultCheckOfMark: TLabel
    Left = 416
    Top = 429
    Width = 147
    Height = 15
    Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090' '#1087#1088#1086#1074#1077#1088#1082#1080' '#1084#1072#1088#1082#1080
  end
  object LabelLastCommand: TLabel
    Left = 752
    Top = 8
    Width = 106
    Height = 15
    Caption = 'LabelLastCommand'
  end
  object MemoMarks: TMemo
    Left = 64
    Top = 75
    Width = 326
    Height = 112
    TabOrder = 0
  end
  object EditSellOrReturn: TEdit
    Left = 429
    Top = 44
    Width = 121
    Height = 23
    TabOrder = 1
    Text = 'sell'
  end
  object ButtonCheckMarksOnKKT: TButton
    Left = 62
    Top = 375
    Width = 161
    Height = 33
    Caption = 'ButtonCheckMarksOnKKT'
    TabOrder = 2
  end
  object ResultCodeCheckOnKKTEdit: TEdit
    Left = 416
    Top = 450
    Width = 121
    Height = 23
    TabOrder = 3
  end
  object ResultDescrCheckOnKKTEdit: TEdit
    Left = 416
    Top = 479
    Width = 121
    Height = 23
    TabOrder = 4
  end
  object CreateDriverKKTButton: TButton
    Left = 413
    Top = 168
    Width = 137
    Height = 25
    Caption = 'CreateDriverKKTButton'
    TabOrder = 5
    OnClick = CreateDriverKKTButtonClick
  end
  object CheckMarkOnKKTButton: TButton
    Left = 252
    Top = 375
    Width = 137
    Height = 33
    Caption = 'CheckMarkOnKKTButton'
    TabOrder = 6
    OnClick = CheckMarkOnKKTButtonClick
  end
  object EditCurrentMarkBase64: TEdit
    Left = 159
    Top = 238
    Width = 136
    Height = 23
    TabOrder = 7
    Text = 'EditCurrentMarkBase64'
  end
  object ButtonCheckStatusKKT: TButton
    Left = 414
    Top = 261
    Width = 136
    Height = 25
    Caption = 'ButtonCheckStatusKKT'
    TabOrder = 8
    OnClick = ButtonCheckStatusKKTClick
  end
  object ButtonCheckPermitMark: TButton
    Left = 254
    Top = 426
    Width = 136
    Height = 32
    Caption = 'ButtonCheckPermitMark'
    TabOrder = 9
    OnClick = ButtonCheckPermitMarkClick
  end
  object EditCodeResultCheckPermit: TEdit
    Left = 608
    Top = 450
    Width = 121
    Height = 23
    TabOrder = 10
  end
  object EditDescrResultPerimtCheck: TEdit
    Left = 607
    Top = 479
    Width = 121
    Height = 23
    TabOrder = 11
  end
  object ButtonCheckPermitMarks: TButton
    Left = 62
    Top = 426
    Width = 161
    Height = 32
    Caption = 'ButtonCheckPermitMarks'
    TabOrder = 12
  end
  object ButtonCheckMark: TButton
    Left = 167
    Top = 464
    Width = 113
    Height = 25
    Caption = 'ButtonCheckMark'
    TabOrder = 13
  end
  object ButtonCheckMArks: TButton
    Left = 167
    Top = 495
    Width = 113
    Height = 25
    Caption = 'ButtonCheckMarks'
    TabOrder = 14
  end
  object ButtonOpenShiftIfNeed: TButton
    Left = 414
    Top = 292
    Width = 136
    Height = 25
    Caption = 'ButtonOpenShiftIfNeed'
    TabOrder = 15
    OnClick = ButtonOpenShiftIfNeedClick
  end
  object ButtonDissconnectFromKKT: TButton
    Left = 414
    Top = 366
    Width = 136
    Height = 25
    Caption = 'ButtonDissconnectFromKKT'
    TabOrder = 16
    OnClick = ButtonDissconnectFromKKTClick
  end
  object ButtonConnectToKKT: TButton
    Left = 413
    Top = 199
    Width = 136
    Height = 25
    Caption = 'ButtonConnectToKKT'
    TabOrder = 17
    OnClick = ButtonConnectToKKTClick
  end
  object ButtonDestroyDriver: TButton
    Left = 414
    Top = 397
    Width = 136
    Height = 25
    Caption = 'ButtonDestroyDriver'
    TabOrder = 18
    OnClick = ButtonDestroyDiverKKTClick
  end
  object CheckBoxEmulationKKT: TCheckBox
    Left = 568
    Top = 8
    Width = 169
    Height = 17
    Caption = 'CheckBoxEmulationKKT'
    Checked = True
    State = cbChecked
    TabOrder = 19
  end
  object EditCassierName: TEdit
    Left = 568
    Top = 44
    Width = 121
    Height = 23
    TabOrder = 20
    Text = #1050#1072#1089#1089#1080#1088
  end
  object ComboBoxPlannedStatusOfMark: TComboBox
    Left = 64
    Top = 325
    Width = 312
    Height = 23
    ItemIndex = 0
    TabOrder = 21
    Text = #1096#1090#1091#1095#1085#1099#1081' '#1090#1086#1074#1072#1088', '#1088#1077#1072#1083#1080#1079#1086#1074#1072#1085
    Items.Strings = (
      #1096#1090#1091#1095#1085#1099#1081' '#1090#1086#1074#1072#1088', '#1088#1077#1072#1083#1080#1079#1086#1074#1072#1085
      #1084#1077#1088#1085#1099#1081' '#1090#1086#1074#1072#1088', '#1074' '#1089#1090#1072#1076#1080#1080' '#1088#1077#1072#1083#1080#1079#1072#1094#1080#1080
      #1096#1090#1091#1095#1085#1099#1081' '#1090#1086#1074#1072#1088', '#1074#1086#1079#1074#1088#1072#1097#1077#1085
      #1095#1072#1089#1090#1100' '#1090#1086#1074#1072#1088#1072', '#1074#1086#1079#1074#1088#1072#1097#1077#1085#1072
      #1096#1090#1091#1095#1085#1099#1081' '#1090#1086#1074#1072#1088', '#1074' '#1089#1090#1072#1076#1080#1080' '#1088#1077#1072#1083#1080#1079#1072#1094#1080#1080
      #1084#1077#1088#1085#1099#1081' '#1090#1086#1074#1072#1088', '#1088#1077#1072#1083#1080#1079#1086#1074#1072#1085
      #1089#1090#1072#1090#1091#1089' '#1090#1086#1074#1072#1088#1072' '#1085#1077' '#1080#1079#1084#1077#1085#1080#1083#1089#1103)
  end
  object ComboBoxCheckType: TComboBox
    Left = 568
    Top = 80
    Width = 145
    Height = 23
    ItemIndex = 0
    TabOrder = 22
    Text = #1055#1088#1086#1076#1072#1078#1072
    Items.Strings = (
      #1055#1088#1086#1076#1072#1078#1072
      #1042#1086#1079#1074#1088#1072#1090)
  end
  object ComboBoxTimeZone: TComboBox
    Left = 568
    Top = 111
    Width = 145
    Height = 23
    ItemIndex = 0
    TabOrder = 23
    Text = 'UTC+2'
    Items.Strings = (
      'UTC+2'
      'UTC+3'
      'UTC+3'
      'UTC+5'
      'UTC+6'
      'UTC+7'
      'UTC+8'
      'UTC+9'
      'UTC+10'
      'UTC+11'
      'UTC+12')
  end
  object LogsMemo: TMemo
    Left = 719
    Top = 44
    Width = 378
    Height = 197
    Lines.Strings = (
      'LogsMemo')
    TabOrder = 24
  end
  object ButtonGetMarksForCheck: TButton
    Left = 63
    Top = 24
    Width = 186
    Height = 25
    Caption = 'ButtonGetMarksForCheck'
    TabOrder = 25
    OnClick = ButtonGetMarksForCheckClick
  end
  object MemoResult: TMemo
    Left = 719
    Top = 262
    Width = 378
    Height = 182
    TabOrder = 26
  end
  object ButtonAddToTable: TButton
    Left = 735
    Top = 464
    Width = 114
    Height = 25
    Caption = 'ButtonAddToTable'
    TabOrder = 27
    OnClick = ButtonAddToTableClick
  end
  object ButtonSaveResults: TButton
    Left = 888
    Top = 464
    Width = 105
    Height = 25
    Caption = 'ButtonSaveResults'
    TabOrder = 28
    OnClick = ButtonSaveResultsClick
  end
  object EditValidationResult: TEdit
    Left = 416
    Top = 512
    Width = 121
    Height = 23
    TabOrder = 29
    Text = 'EditValidationResult'
  end
  object ButtonGetNextMark: TButton
    Left = 159
    Top = 199
    Width = 136
    Height = 25
    Caption = 'ButtonGetNextMark'
    TabOrder = 30
    OnClick = ButtonGetNextMarkClick
  end
  object EditUUID: TEdit
    Left = 568
    Top = 508
    Width = 121
    Height = 23
    TabOrder = 31
    Text = 'EditUUID'
  end
  object EditTimeStamp: TEdit
    Left = 568
    Top = 537
    Width = 121
    Height = 23
    TabOrder = 32
    Text = 'EditTimeStamp'
  end
  object EditInst: TEdit
    Left = 695
    Top = 508
    Width = 121
    Height = 23
    TabOrder = 33
    Text = 'EditInst'
  end
  object EditVer: TEdit
    Left = 695
    Top = 537
    Width = 121
    Height = 23
    TabOrder = 34
    Text = 'EditVer'
  end
  object EditCurrentMark: TEdit
    Left = 159
    Top = 267
    Width = 136
    Height = 23
    TabOrder = 35
    Text = 'EditCurrentMark'
  end
  object EditCurrentMarkCodeIdent: TEdit
    Left = 159
    Top = 296
    Width = 136
    Height = 23
    TabOrder = 36
    Text = 'EditCurrentMarkCodeIdent'
  end
  object ButtonRecieptWasClosed: TButton
    Left = 959
    Top = 511
    Width = 121
    Height = 30
    Caption = 'ButtonRecieptWasClosed'
    TabOrder = 37
    OnClick = ButtonRecieptWasClosedClick
  end
  object ButtonCancelRecipt: TButton
    Left = 959
    Top = 547
    Width = 121
    Height = 35
    Caption = 'ButtonCancelRecipt'
    TabOrder = 38
    OnClick = ButtonCancelReciptClick
  end
  object ButtonReceiptClosing: TButton
    Left = 832
    Top = 511
    Width = 105
    Height = 25
    Caption = 'ButtonReceiptClosing'
    TabOrder = 39
    OnClick = ButtonReceiptClosingClick
  end
  object TimerForCommandsFrom1c: TTimer
    OnTimer = TimerForCommandsFrom1cTimer
    Left = 424
    Top = 104
  end
  object TimerCheckMarks: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = TimerCheckMarksTimer
    Left = 336
    Top = 16
  end
end
