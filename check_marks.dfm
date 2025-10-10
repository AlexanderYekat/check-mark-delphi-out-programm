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
  TextHeight = 15
  object LabelCurrentIdOfTask: TLabel
    Left = 1008
    Top = 239
    Width = 114
    Height = 15
    Caption = 'LabelCurrentIdOfTask'
  end
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
    Left = 567
    Top = 205
    Width = 77
    Height = 15
    Caption = 'not connected'
  end
  object LabelResultCommandDescr: TLabel
    Left = 454
    Top = 531
    Width = 16
    Height = 15
    Caption = 'OK'
  end
  object LabelResultCommandCode: TLabel
    Left = 454
    Top = 510
    Width = 6
    Height = 15
    Caption = '0'
  end
  object LabelCaptionResultCommans: TLabel
    Left = 454
    Top = 488
    Width = 181
    Height = 15
    Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090#1099' '#1074#1099#1087#1086#1083#1085#1077#1085#1080#1103' '#1082#1086#1084#1072#1085#1076':'
  end
  object MemoMarks: TMemo
    Left = 64
    Top = 304
    Width = 185
    Height = 89
    Lines.Strings = (
      'MemoMarks')
    TabOrder = 0
  end
  object EditSellOrReturn: TEdit
    Left = 64
    Top = 227
    Width = 121
    Height = 23
    TabOrder = 1
    Text = 'EditSellOrReturn'
  end
  object ButtonCheckMarksOnKKT: TButton
    Left = 63
    Top = 407
    Width = 161
    Height = 33
    Caption = 'ButtonCheckMarksOnKKT'
    TabOrder = 2
  end
  object MemoJSONResultCheckOnKKT: TMemo
    Left = 672
    Top = 268
    Width = 185
    Height = 89
    Lines.Strings = (
      'MemoJSONResultCheckOnKKT')
    TabOrder = 3
  end
  object ResultCodeCheckOnKKTEdit: TEdit
    Left = 672
    Top = 210
    Width = 121
    Height = 23
    TabOrder = 4
    Text = 'ResultCodeCheckOnKKTEdit'
  end
  object ResultDescrCheckOnKKTEdit: TEdit
    Left = 672
    Top = 239
    Width = 121
    Height = 23
    TabOrder = 5
    Text = 'ResultCodeCheckOnKKTEdit'
  end
  object CreateDriverKKTButton: TButton
    Left = 413
    Top = 168
    Width = 137
    Height = 25
    Caption = 'CreateDriverKKTButton'
    TabOrder = 6
    OnClick = CreateDriverKKTButtonClick
  end
  object CheckMarkOnKKTButton: TButton
    Left = 253
    Top = 407
    Width = 137
    Height = 33
    Caption = 'CheckMarkOnKKTButton'
    TabOrder = 7
    OnClick = CheckMarkOnKKTButtonClick
  end
  object EditMark: TEdit
    Left = 255
    Top = 323
    Width = 136
    Height = 23
    TabOrder = 8
    Text = 'EditMark'
  end
  object ButtonGetTasks: TButton
    Left = 24
    Top = 43
    Width = 97
    Height = 25
    Caption = 'ButtonGetTasks'
    TabOrder = 9
  end
  object MemoTasks: TMemo
    Left = 127
    Top = 73
    Width = 217
    Height = 30
    Lines.Strings = (
      'MemoTasks')
    TabOrder = 10
  end
  object MemoCurrentTask: TMemo
    Left = 63
    Top = 169
    Width = 218
    Height = 52
    Lines.Strings = (
      'MemoCurrentTask')
    TabOrder = 11
  end
  object ButtonCheckStatusKKT: TButton
    Left = 414
    Top = 261
    Width = 136
    Height = 25
    Caption = 'ButtonCheckStatusKKT'
    TabOrder = 12
    OnClick = ButtonCheckStatusKKTClick
  end
  object MemoResultJSONTask: TMemo
    Left = 688
    Top = 462
    Width = 185
    Height = 89
    Lines.Strings = (
      'MemoResultJSONTask')
    TabOrder = 13
  end
  object EditCodeResultOfTask: TEdit
    Left = 688
    Top = 401
    Width = 121
    Height = 23
    TabOrder = 14
    Text = 'EditCodeResultOfTask'
  end
  object EditDescrResultOfTask: TEdit
    Left = 688
    Top = 430
    Width = 121
    Height = 23
    TabOrder = 15
    Text = 'EditCodeResultOfTask'
  end
  object ButtonSaveResultTask: TButton
    Left = 879
    Top = 461
    Width = 137
    Height = 25
    Caption = 'ButtonSaveResultTask'
    TabOrder = 16
  end
  object EditSeesionOfTasks: TEdit
    Left = 127
    Top = 44
    Width = 121
    Height = 23
    TabOrder = 17
    Text = 'EditSeesionOfTasks'
  end
  object MemoAllMarksOfSession: TMemo
    Left = 350
    Top = 44
    Width = 200
    Height = 89
    Lines.Strings = (
      'MemoAllMarksOfSession')
    TabOrder = 18
  end
  object ButtonCheckPermitMark: TButton
    Left = 255
    Top = 458
    Width = 136
    Height = 32
    Caption = 'ButtonCheckPermitMark'
    TabOrder = 19
  end
  object EditCodeResultCheckPermit: TEdit
    Left = 864
    Top = 210
    Width = 121
    Height = 23
    TabOrder = 20
    Text = 'EditCodeResultCheckPermit'
  end
  object EditDescrResultPerimtCheck: TEdit
    Left = 863
    Top = 239
    Width = 121
    Height = 23
    TabOrder = 21
    Text = 'EditDescrResultPerimtCheck'
  end
  object MemoJSONResultCheckPermit: TMemo
    Left = 863
    Top = 268
    Width = 162
    Height = 89
    Lines.Strings = (
      'MemoJSONResultCheckPer'
      'm'
      'it')
    TabOrder = 22
  end
  object ButtonCheckPermitMarks: TButton
    Left = 63
    Top = 458
    Width = 161
    Height = 32
    Caption = 'ButtonCheckPermitMarks'
    TabOrder = 23
  end
  object ButtonCheckMark: TButton
    Left = 168
    Top = 496
    Width = 113
    Height = 25
    Caption = 'ButtonCheckMark'
    TabOrder = 24
  end
  object ButtonCheckMArks: TButton
    Left = 168
    Top = 527
    Width = 113
    Height = 25
    Caption = 'ButtonCheckMArks'
    TabOrder = 25
  end
  object ButtonFromResultCheckToResultOfTask: TButton
    Left = 1048
    Top = 294
    Width = 90
    Height = 25
    Caption = 'ButtonFromResultCheckToResultOfTask'
    TabOrder = 26
  end
  object EditCurrentIDOfTask: TEdit
    Left = 63
    Top = 140
    Width = 113
    Height = 23
    TabOrder = 27
    Text = 'EditCurrentIDOfTask'
  end
  object ButtonRemoveTask: TButton
    Left = 879
    Top = 508
    Width = 137
    Height = 25
    Caption = 'ButtonRemoveTask'
    TabOrder = 28
  end
  object ButtonGetNextTask: TButton
    Left = 64
    Top = 109
    Width = 113
    Height = 25
    Caption = 'ButtonGetNextTask'
    TabOrder = 29
  end
  object ButtonCreateNewSession: TButton
    Left = 24
    Top = 8
    Width = 152
    Height = 25
    Caption = 'ButtonCreateNewSession'
    TabOrder = 30
  end
  object ButtonFinishSession: TButton
    Left = 784
    Top = 8
    Width = 129
    Height = 25
    Caption = 'ButtonFinishSession'
    TabOrder = 31
  end
  object ButtonOpenShiftIfNeed: TButton
    Left = 414
    Top = 292
    Width = 136
    Height = 25
    Caption = 'ButtonOpenShiftIfNeed'
    TabOrder = 32
    OnClick = ButtonOpenShiftIfNeedClick
  end
  object ButtonDissconnectFromKKT: TButton
    Left = 414
    Top = 366
    Width = 136
    Height = 25
    Caption = 'ButtonDissconnectFromKKT'
    TabOrder = 33
    OnClick = ButtonDissconnectFromKKTClick
  end
  object ButtonConnectToKKT: TButton
    Left = 413
    Top = 199
    Width = 136
    Height = 25
    Caption = 'ButtonConnectToKKT'
    TabOrder = 34
    OnClick = ButtonConnectToKKTClick
  end
  object ButtonDestroyDriver: TButton
    Left = 414
    Top = 397
    Width = 136
    Height = 25
    Caption = 'ButtonDestroyDriver'
    TabOrder = 35
    OnClick = ButtonDestroyDriverClick
  end
  object CheckBoxEmulationKKT: TCheckBox
    Left = 568
    Top = 8
    Width = 169
    Height = 17
    Caption = 'CheckBoxEmulationKKT'
    Checked = True
    State = cbChecked
    TabOrder = 36
  end
  object EditCassierName: TEdit
    Left = 568
    Top = 44
    Width = 121
    Height = 23
    TabOrder = 37
    Text = #1050#1072#1089#1089#1080#1088
  end
  object ComboBoxPlannedStatusOfMark: TComboBox
    Left = 64
    Top = 256
    Width = 312
    Height = 23
    ItemIndex = 0
    TabOrder = 38
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
    TabOrder = 39
    Text = #1087#1088#1086#1076#1072#1078#1072
    Items.Strings = (
      #1087#1088#1086#1076#1072#1078#1072
      #1074#1086#1079#1074#1088#1072#1090)
  end
  object ComboBoxTimeZone: TComboBox
    Left = 568
    Top = 111
    Width = 145
    Height = 23
    ItemIndex = 0
    TabOrder = 40
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
end
