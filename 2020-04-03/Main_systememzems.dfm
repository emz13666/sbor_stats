object Form1System_emz_ems111111: TForm1System_emz_ems111111
  Left = 509
  Top = 324
  BorderStyle = bsNone
  Caption = 'System_emz_ems111111'
  ClientHeight = 61
  ClientWidth = 143
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 100000
    OnTimer = Timer1Timer
    Left = 48
    Top = 16
  end
  object ADODataSet1: TADODataSet
    ConnectionString = 
      'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql' +
      '_ubiquiti'
    Parameters = <>
    Left = 88
    Top = 16
  end
end
