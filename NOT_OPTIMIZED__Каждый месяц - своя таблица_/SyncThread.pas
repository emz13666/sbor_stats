unit SyncThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util;

type
  TMySyncThread = class(TThread)
  private
    { Private declarations }
    rec_count_local_statss: longint;
    id_statss_local, id_modem_statss_local: longint;
     mac_ap_statss_local: string;
     date_statss_local, time_statss_local: TDateTime;
     sig_lev_statss_local, f_online_statss_local,f_status: integer;
  protected
    Procedure DoWork;
    procedure GetCountLocalStatss;
    procedure GetStatss_local;
    procedure PutToMySQL;
    procedure DeleteFromStatsLocal;
    procedure Execute; override;
  public

  end;

var flag_ok: boolean;

implementation

uses SysUtils, MainUnit;

{ Important: Methods and properties of objects in VCL or CLX can only be used
  in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TMyTimerThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }


procedure TMySyncThread.DeleteFromStatsLocal;
begin
 try
    Form1.statss_local.First;
    if Form1.statss_local.Locate('id',id_statss_local,[]) then begin
      Form1.statss_local.Delete;
    end;
 except
    mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении DeleteFromStatsLocal в потоке синхронизации');
    mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
 end;
end;

procedure TMySyncThread.DoWork;
var t1: cardinal;
begin
  t1 := GetTickCount;
  Synchronize(GetCountLocalStatss);
  while (rec_count_local_statss>0)and(GetTickCount-t1 < 15000) do
    begin
       Synchronize(GetStatss_local);
       PutToMySQL;
       if flag_ok then Synchronize(DeleteFromStatsLocal);
       Synchronize(GetCountLocalStatss);
    end;
end;


procedure TMySyncThread.Execute;
begin
  { Place thread code here }
  FreeOnTerminate := True;
  repeat
    DoWork;
    Sleep(5000);
  until Terminated;
end;




procedure TMySyncThread.GetCountLocalStatss;
begin
  try
    rec_count_local_statss := Form1.statss_local.RecordCount;
  except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении GetCountLocalStatss в потоке синхронизации');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TMySyncThread.GetStatss_local;
begin
  with form1 do
  try
    if not statss_local.Active then statss_local.Open;
    statss_local.First;
    id_statss_local := statss_localid.AsInteger;
    id_modem_statss_local := statss_localid_modem.AsInteger;
    sig_lev_statss_local := statss_localsignal_level.AsInteger;
    if sig_lev_statss_local=-100 then f_online_statss_local:=0 else f_online_statss_local:=1;
    date_statss_local := statss_localdate.AsDateTime;
    time_statss_local := statss_localtime.AsDateTime;
    mac_ap_statss_local := statss_localmac_ap.AsString;
    f_status := statss_localstatus.AsInteger;
  except
    mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при чтении записи из локальной БД в потоке синхронизации');
    mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TMySyncThread.PutToMySQL;
begin
  with form1 do
  begin
    Query.Close;
    Query.SQL.Text := 'Insert into statss'+FormatDateTime('mm',date_statss_local)+'(id_modem, date, mac_ap,signal_level, time, status) values('+
            IntToStr(id_modem_statss_local)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local))+','+
            QuotedStr(mac_ap_statss_local)+','+
            QuotedStr(IntToStr(sig_lev_statss_local))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local))+','+
            IntToStr(f_status)+')';
    flag_ok := true;
    try
      ADOConnection1.Close;
      ADOConnection1.Open;
      Query.ExecSQL;
    except
      ADOConnection1.Close;
      flag_ok := false;
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении '+Query.SQL.Text+' в потоке синхронизации');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
    end;
    Query.Close;

    Query.SQL.Text := 'Update modems set online='+Inttostr(f_online_statss_local)+' where id_modem='+IntToStr(id_modem_statss_local);
    flag_ok := true;
    try
      ADOConnection1.Close;
      ADOConnection1.Open;
      Query.ExecSQL;
    except
      ADOConnection1.Close;
      flag_ok := false;
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении '+Query.SQL.Text+' в потоке синхронизации');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
    end;
    Query.Close;
 end;
end;

end.

