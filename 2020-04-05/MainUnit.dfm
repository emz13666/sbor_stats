object Form1: TForm1
  Left = 371
  Top = 188
  Caption = #1057#1073#1086#1088' '#1089#1090#1072#1090#1080#1089#1090#1080#1082#1080' Ubiquiti'
  ClientHeight = 410
  ClientWidth = 753
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 319
    Width = 95
    Height = 13
    Caption = #1050#1086#1083'-'#1074#1086' '#1089#1090#1088#1086#1082' '#1083#1086#1075#1072':'
  end
  object Label2: TLabel
    Left = 109
    Top = 319
    Width = 18
    Height = 13
    Caption = '000'
  end
  object Label3: TLabel
    Left = 8
    Top = 338
    Width = 91
    Height = 26
    Caption = #1050#1086#1083'-'#1074#1086' '#1079#1072#1087#1080#1089#1077#1081' '#1074' '#1083#1086#1082#1072#1083#1100#1085#1086#1081' '#1041#1044':'
    WordWrap = True
  end
  object Label4: TLabel
    Left = 121
    Top = 338
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label5: TLabel
    Left = 121
    Top = 352
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label6: TLabel
    Left = 320
    Top = 349
    Width = 85
    Height = 13
    Caption = 'snmp timeout, sec'
  end
  object Label7: TLabel
    Left = 269
    Top = 374
    Width = 144
    Height = 26
    Alignment = taCenter
    Caption = #1055#1077#1088#1080#1086#1076' '#1086#1087#1088#1086#1089#1072' '#1085#1077#1076#1086#1089#1090#1091#1087#1085#1086#1075#1086' '#1091#1089#1090#1088#1086#1081#1089#1090#1074#1072', '#1089':'
    WordWrap = True
  end
  object Label8: TLabel
    Left = 11
    Top = 374
    Width = 92
    Height = 13
    Caption = #1055#1077#1088#1080#1086#1076' '#1086#1087#1088#1086#1089#1072', '#1089':'
    WordWrap = True
  end
  object Button1: TButton
    Left = 494
    Top = 350
    Width = 59
    Height = 25
    Caption = 'Clear log'
    TabOrder = 0
    Visible = False
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 753
    Height = 313
    Align = alTop
    ScrollBars = ssVertical
    TabOrder = 1
    OnChange = Memo1Change
  end
  object Button33: TButton
    Left = 678
    Top = 381
    Width = 75
    Height = 25
    Caption = 'Clear local'
    TabOrder = 2
    OnClick = Button33Click
  end
  object Button2: TButton
    Left = 584
    Top = 381
    Width = 79
    Height = 25
    Caption = 'stop sbor'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 494
    Top = 381
    Width = 75
    Height = 25
    Caption = 'Start sbor'
    Enabled = False
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 664
    Top = 350
    Width = 89
    Height = 25
    Caption = 'Stop_checkWIFI'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 559
    Top = 350
    Width = 99
    Height = 25
    Caption = 'Close_Local_stats'
    TabOrder = 6
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 494
    Top = 319
    Width = 259
    Height = 25
    Caption = 'Stop MoveToStatss_oldThread'
    TabOrder = 7
    OnClick = Button6Click
  end
  object chkPredvPing: TCheckBox
    Left = 320
    Top = 319
    Width = 154
    Height = 17
    Caption = #1055#1088#1077#1076#1074#1072#1088#1080#1090#1077#1083#1100#1085#1099#1081' '#1087#1080#1085#1075
    TabOrder = 8
  end
  object edtSnmpTimeout: TSpinEdit
    Left = 421
    Top = 346
    Width = 57
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 9
    Value = 2
  end
  object edtPingUnreachble: TSpinEdit
    Left = 421
    Top = 374
    Width = 57
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 10
    Value = 60
  end
  object edtPeriodOprosa: TSpinEdit
    Left = 109
    Top = 371
    Width = 49
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 11
    Value = 10
  end
  object chkFirmwareVer: TCheckBox
    Left = 168
    Top = 319
    Width = 146
    Height = 17
    Caption = #1055#1088#1086#1074#1077#1088#1103#1090#1100' firmware ver'
    Checked = True
    State = cbChecked
    TabOrder = 12
  end
  object chCollectStatsBullet: TCheckBox
    Left = 168
    Top = 342
    Width = 137
    Height = 17
    Hint = 
      #1057#1086#1073#1080#1088#1072#1090#1100' '#1089' '#1073#1091#1083#1080#1090#1086#1074' '#1080#1085#1092#1086#1088#1084#1072#1094#1080#1102' '#1086' '#1079#1072#1075#1088#1091#1079#1082#1077' '#1087#1088#1086#1094#1077#1089#1089#1086#1088#1072',  '#1087#1072#1084#1103#1090#1080' '#1080' '#1090 +
      #1088#1072#1092#1080#1082
    Caption = 'collect netstat clients'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 13
  end
  object chkSmotr2: TCheckBox
    Left = 168
    Top = 365
    Width = 123
    Height = 17
    Caption = 'check SMOTR_2'
    Checked = True
    State = cbChecked
    TabOrder = 14
    OnClick = Button4Click
  end
  object Query: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 440
    Top = 120
  end
  object ADOConnection1: TADOConnection
    Connected = True
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql' +
      '_ubiquiti'
    LoginPrompt = False
    Left = 136
    Top = 240
  end
  object Query1: TADOQuery
    Connection = ADOConnection2
    Parameters = <>
    Left = 664
    Top = 88
  end
  object Modems: TADOQuery
    Connection = ADOConnection1
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      
        'SELECT m.id_modem, m.is_access_point, m.is_ap_repeater, m.mac_wd' +
        's_peer, m.firmware, e.name, e.ip_address, e.equipment_type,'
      
        '    e.useInMonitoring  FROM modems m, equipment e WHERE e.equipm' +
        'ent_type<=3 and e.useInMonitoring=1 and '
      '    e.ip_address=m.ip_address  order by e.name')
    Left = 224
    Top = 208
    object Modemsid_modem: TLargeintField
      FieldName = 'id_modem'
    end
    object Modemsis_access_point: TSmallintField
      FieldName = 'is_access_point'
    end
    object Modemsis_ap_repeater: TWordField
      FieldName = 'is_ap_repeater'
    end
    object Modemsmac_wds_peer: TStringField
      FieldName = 'mac_wds_peer'
      Size = 50
    end
    object Modemsfirmware: TStringField
      FieldName = 'firmware'
      FixedChar = True
      Size = 8
    end
    object Modemsname: TStringField
      FieldName = 'name'
      Size = 50
    end
    object Modemsip_address: TStringField
      FieldName = 'ip_address'
      Size = 50
    end
    object Modemsequipment_type: TIntegerField
      FieldName = 'equipment_type'
    end
    object ModemsuseInMonitoring: TSmallintField
      FieldName = 'useInMonitoring'
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 200
    Top = 104
    object N1: TMenuItem
      Caption = #1054#1090#1082#1088#1099#1090#1100
      OnClick = RxTrayIcon1DblClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object N5: TMenuItem
      Caption = #1042#1099#1081#1090#1080
      OnClick = N5Click
    end
  end
  object ADOConnection2: TADOConnection
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql' +
      '_ubiquiti'
    LoginPrompt = False
    Provider = 'MSDASQL.1'
    Left = 657
    Top = 40
  end
  object QueryWifi_log: TADOQuery
    Connection = ConnectionWifi_log
    Parameters = <>
    SQL.Strings = (
      'SELECT * FROM wifi_log ORDER BY id DESC LIMIT 1 ')
    Left = 552
    Top = 248
  end
  object ConnectionWifi_log: TADOConnection
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql' +
      '_ubiquiti'
    LoginPrompt = False
    Provider = 'MSDASQL.1'
    Left = 553
    Top = 192
  end
  object RxTrayIcon1: TTrayIcon
    Icon.Data = {
      0000010001002020100000000000E80200001600000028000000200000004000
      0000010004000000000000020000000000000000000000000000000000000000
      0000000080000080000000808000800000008000800080800000C0C0C0008080
      80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF111
      111111111111111111111111111FF111111111111111111EE1EE1EE1EE1FF1EE
      11BB1BB1BB1BB11EE1EE1EE1EE1FF1EE11BB1BB1BB1BB11111111111EE1FF1EE
      11BB1BB1BB1BB11EE1EE1EE1EE1FF1EE11BB1BB1BB1BB11EE1EE1EE1111FF1EE
      111111111111111111111111111FF111111111111111111111111111111FF111
      111111111111111111111111111FF111111111111111111111111111111FFFFF
      FFFF66666FFFFFF66666FFFFFFFF000000000666000000006660000000000000
      0000666000000000066600000000000000066600000000000066600000000000
      0066600000000300000666000000000006660030000033300000666000000000
      6660003300033333000006660000000666000003303333033000006660000066
      0000000033333000330000006600066000000000033300000330000006606000
      000000000030000000330000000600000000000000000000000000000000E7C9
      9F9FE7C99F9FE0099F9FF0198C03F3B99403F93FFF9FFD79FF9FFEF9FF9FFFFF
      FFFF000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FF8FF1FFFF1FF8FFFE3FFC7FFC7F
      BE3FF8DF1F1FF1CE0F8FE3E427C7CFF073F39FF8F9F97FFDFCFEFFFFFFFF}
    PopupMenu = PopupMenu1
    OnDblClick = RxTrayIcon1DblClick
    Left = 296
    Top = 256
  end
  object stats_ap_local: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 320
    Top = 96
    object stats_ap_localid: TAutoIncField
      FieldName = 'id'
    end
    object stats_ap_localid_modem: TIntegerField
      FieldName = 'id_modem'
    end
    object stats_ap_localsignal_level: TSmallintField
      FieldName = 'signal_level'
    end
    object stats_ap_localdate: TDateField
      FieldName = 'date'
    end
    object stats_ap_localtime: TTimeField
      FieldName = 'time'
    end
    object stats_ap_localloadavg: TStringField
      FieldName = 'loadavg'
    end
    object stats_ap_localmemfree: TStringField
      FieldName = 'memfree'
    end
    object stats_ap_localrx_octets_eth0: TStringField
      FieldName = 'rx_octets_eth0'
    end
    object stats_ap_localtx_octets_eth0: TStringField
      FieldName = 'tx_octets_eth0'
    end
  end
  object statss_local: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 320
    Top = 40
    object statss_localid: TAutoIncField
      FieldName = 'id'
    end
    object statss_localid_modem: TIntegerField
      FieldName = 'id_modem'
    end
    object statss_localmac_ap: TStringField
      FieldName = 'mac_ap'
    end
    object statss_localsignal_level: TSmallintField
      FieldName = 'signal_level'
    end
    object statss_localdate: TDateField
      FieldName = 'date'
    end
    object statss_localtime: TTimeField
      FieldName = 'time'
    end
    object statss_localstatus: TSmallintField
      FieldName = 'status'
    end
    object statss_localx: TIntegerField
      FieldName = 'x'
    end
    object statss_localy: TIntegerField
      FieldName = 'y'
    end
  end
  object FormStorage1: TFormStorage
    Options = []
    UseRegistry = False
    StoredProps.Strings = (
      'chkFirmwareVer.Checked'
      'chkPredvPing.Checked'
      'edtPeriodOprosa.Value'
      'edtPingUnreachble.Value'
      'edtSnmpTimeout.Value'
      'chCollectStatsBullet.Checked'
      'chkSmotr2.Checked')
    StoredValues = <>
    Left = 384
    Top = 248
  end
  object ADOConnection3: TADOConnection
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql' +
      '_ubiquiti'
    LoginPrompt = False
    Provider = 'MSDASQL.1'
    Left = 473
    Top = 16
  end
end
