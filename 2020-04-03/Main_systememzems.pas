unit Main_systememzems;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, DB, DateUtils, ADODB;

type
  TForm1System_emz_ems111111 = class(TForm)
    Timer1: TTimer;
    ADODataSet1: TADODataSet;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1System_emz_ems111111: TForm1System_emz_ems111111;

implementation

{$R *.dfm}

procedure TForm1System_emz_ems111111.Timer1Timer(Sender: TObject);
var cnt,i: Longint;
begin
try
  i:= 1900;
  ADODataSet1.CommandText := 'SELECT count(*) '+
    'FROM  `statss` '+
    'WHERE DATE = '+QuotedStr(FormatDateTime('yyyy-mm-dd',now));
  ADODataSet1.Open;
  cnt := ADODataSet1.Fields[0].AsInteger;
  ADODataSet1.Close;

  if cnt>0 then begin
    ADODataSet1.CommandText := 'SELECT MAX( TIME ) '+
    'FROM  `statss` '+
    'WHERE DATE = '+QuotedStr(FormatDateTime('yyyy-mm-dd',now));
    ADODataSet1.Open;
    i := SecondsBetween(now, ADODataSet1.Fields[0].AsDateTime);
    ADODataSet1.Close;
  end;


  if (i > 1800) then
  begin
    WinExec('taskkill.exe /F /IM sbor_stats.exe', SW_HIDE);
    sleep(5000);

    WinExec(PChar(ExtractFilePath(Application.ExeName)+'sbor_stats.exe'), SW_NORMAL);
  end;

 except
 end;
end;

end.
