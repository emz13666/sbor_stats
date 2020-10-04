object Form1: TForm1
  Left = 264
  Top = 160
  Width = 761
  Height = 466
  Caption = #1057#1073#1086#1088' '#1089#1090#1072#1090#1080#1089#1090#1080#1082#1080' Ubiquiti'
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
    Left = 7
    Top = 400
    Width = 78
    Height = 13
    Caption = #1050#1086#1083'-'#1074#1086' '#1086#1096#1080#1073#1086#1082':'
  end
  object Label2: TLabel
    Left = 88
    Top = 401
    Width = 18
    Height = 13
    Caption = '000'
  end
  object Label3: TLabel
    Left = 192
    Top = 400
    Width = 122
    Height = 13
    Caption = #1050#1086#1083'-'#1074#1086' '#1074' '#1083#1086#1082#1072#1083#1100#1085#1086#1081' '#1041#1044':'
  end
  object Label4: TLabel
    Left = 326
    Top = 401
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Button1: TButton
    Left = 392
    Top = 394
    Width = 75
    Height = 25
    Caption = 'Clear log'
    TabOrder = 0
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
    Left = 666
    Top = 394
    Width = 75
    Height = 25
    Caption = 'Clear local'
    TabOrder = 2
    OnClick = Button33Click
  end
  object Button2: TButton
    Left = 568
    Top = 395
    Width = 75
    Height = 25
    Caption = 'stop sbor'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 483
    Top = 395
    Width = 75
    Height = 25
    Caption = 'Start sbor'
    Enabled = False
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 536
    Top = 360
    Width = 129
    Height = 25
    Caption = 'Stop_checkWIFI'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 424
    Top = 360
    Width = 99
    Height = 25
    Caption = 'Close_Local_stats'
    TabOrder = 6
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 440
    Top = 320
    Width = 169
    Height = 25
    Caption = 'Stop MoveToStatss_oldThread'
    TabOrder = 7
    OnClick = Button6Click
  end
  object RxTrayIcon1: TRxTrayIcon
    Hint = 'Ubiquiti stats'
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
    OnClick = RxTrayIcon1Click
    OnDblClick = RxTrayIcon1DblClick
    Left = 144
    Top = 112
  end
  object Query: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 200
    Top = 296
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
  object statss_local: TClientDataSet
    Aggregates = <>
    FileName = 'Z:\projects\ubiquiti_stats\sbor_stats\statss_local.cds'
    FieldDefs = <>
    IndexDefs = <>
    Params = <>
    StoreDefs = True
    Left = 320
    Top = 160
    object statss_localid: TAutoIncField
      FieldName = 'id'
      ReadOnly = True
    end
    object statss_localid_modem: TIntegerField
      FieldName = 'id_modem'
    end
    object statss_localmac_ap: TWideStringField
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
    object statss_localx: TSmallintField
      FieldName = 'x'
    end
    object statss_localy: TSmallintField
      FieldName = 'y'
    end
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
      
        'SELECT m.id_modem, m.is_access_point, m.firmware, e.name, e.ip_a' +
        'ddress, e.equipment_type, e.useInMonitoring  FROM modems m, equi' +
        'pment e WHERE e.equipment_type<=3 and e.useInMonitoring=1 and e.' +
        'ip_address=m.ip_address  order by e.name')
    Left = 224
    Top = 208
    object Modemsid_modem: TLargeintField
      FieldName = 'id_modem'
      ReadOnly = True
    end
    object Modemsname: TWideStringField
      FieldName = 'name'
      Size = 50
    end
    object Modemsip_address: TWideStringField
      FieldName = 'ip_address'
      Size = 50
    end
    object Modemsequipment_type: TIntegerField
      FieldName = 'equipment_type'
    end
    object ModemsuseInMonitoring: TSmallintField
      FieldName = 'useInMonitoring'
    end
    object Modemsis_access_point: TSmallintField
      FieldName = 'is_access_point'
    end
    object Modemsfirmware: TWideStringField
      FieldName = 'firmware'
      FixedChar = True
      Size = 8
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
    Left = 665
    Top = 56
  end
  object QueryWifi_log: TADOQuery
    Connection = ConnectionWifi_log
    Parameters = <>
    SQL.Strings = (
      'SELECT * FROM wifi_log ORDER BY id DESC LIMIT 1 ')
    Left = 552
    Top = 272
  end
  object ConnectionWifi_log: TADOConnection
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql' +
      '_ubiquiti'
    LoginPrompt = False
    Provider = 'MSDASQL.1'
    Left = 553
    Top = 240
  end
end
