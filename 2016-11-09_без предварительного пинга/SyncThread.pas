unit SyncThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util;

type
  TMySyncThread = class(TThread)
  private
    { Private declarations }
    rec_count_local_statss : longint;
    id_statss_local, id_modem_statss_local: longint;
    loadavg, memfree: AnsiString;
    rx_octets_eth0, tx_octets_eth0: AnsiString;
    mac_ap_statss_local: AnsiString;
    date_statss_local, time_statss_local: TDateTime;
    sig_lev_statss_local, f_online_statss_local,f_status: integer;

  protected
    Procedure DoWork;
    Procedure DoWork_ap;
    procedure GetCountLocalStatss;
    procedure GetCountLocalStatss_ap;
    procedure GetStatss_local;
    procedure GetStats_ap_local;
    procedure PutToMySQL;
    procedure PutToMySQL_AP;
    procedure DeleteFromStatsLocal;
    procedure DeleteFromStatsLocal_ap;
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

procedure TMySyncThread.DeleteFromStatsLocal_ap;
begin
 try
    Form1.stats_ap_local.First;
    if Form1.stats_ap_local.Locate('id',id_statss_local,[]) then begin
      Form1.stats_ap_local.Delete;
    end;
 except
    mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении DeleteFromStatsLocal_ap в потоке синхронизации');
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
       // закомментировано для отладки
       PutToMySQL;
       if flag_ok then Synchronize(DeleteFromStatsLocal);
       Synchronize(GetCountLocalStatss);
    end;
end;


procedure TMySyncThread.DoWork_ap;
var t1: cardinal;
begin
  t1 := GetTickCount;
  Synchronize(GetCountLocalStatss_ap);
  while (rec_count_local_statss>0)and(GetTickCount-t1 < 15000) do
    begin
       Synchronize(GetStats_ap_local);
       // закомментировано для отладки
       PutToMySQL_ap;
       if flag_ok then Synchronize(DeleteFromStatsLocal_ap);
       Synchronize(GetCountLocalStatss_ap);
    end;
end;

procedure TMySyncThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  repeat
   DoWork;
   DoWork_ap;
   begin_tick := GetTickCount;
    while GetTickCount - begin_tick < 5000 do
      if not Terminated then sleep(10) else break;
  until Terminated;
end;

procedure TMySyncThread.GetCountLocalStatss;
begin
  try
    if not Form1.statss_local.Active then Form1.statss_local.Open;
    rec_count_local_statss := Form1.statss_local.RecordCount;
    if rec_count_local_statss=0 then begin
      form1.statss_local.EmptyDataSet;
      form1.statss_local.SaveToFile();
      form1.statss_local.Close;
      form1.statss_local.Open;
    end;
  except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении GetCountLocalStatss в потоке синхронизации');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TMySyncThread.GetCountLocalStatss_ap;
begin
  try
    if not Form1.stats_ap_local.Active then Form1.stats_ap_local.Open;
    rec_count_local_statss := Form1.stats_ap_local.RecordCount;
    if rec_count_local_statss=0 then begin
      form1.stats_ap_local.EmptyDataSet;
      form1.stats_ap_local.SaveToFile();
      form1.stats_ap_local.Close;
      form1.stats_ap_local.Open;
    end;
  except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении GetCountLocalStatss_ap в потоке синхронизации');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TMySyncThread.GetStatss_local;
begin
  with form1 do
  try
    if not statss_local.Active then statss_local.Open;
    statss_local.Last;
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

procedure TMySyncThread.GetStats_ap_local;
begin
  with form1 do
  try
    if not stats_ap_local.Active then stats_ap_local.Open;
    stats_ap_local.Last;
    id_statss_local := stats_ap_localid.AsInteger;
    id_modem_statss_local := stats_ap_localid_modem.AsInteger;
    sig_lev_statss_local := stats_ap_localsignal_level.AsInteger;
    if sig_lev_statss_local=-100 then f_online_statss_local:=0 else f_online_statss_local:=1;
    date_statss_local := stats_ap_localDate.AsDateTime;
    time_statss_local := stats_ap_localTime.AsDateTime;
    loadavg := stats_ap_localloadavg.AsAnsiString;
    memfree := stats_ap_localmemfree.AsAnsiString;
    rx_octets_eth0 :=stats_ap_localrx_octets_eth0.AsAnsiString;
    tx_octets_eth0 := stats_ap_localtx_octets_eth0.AsAnsiString;
  except
    mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при чтении записи из локальной БД_ap в потоке синхронизации');
    mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TMySyncThread.PutToMySQL;
begin
  with form1 do
  begin
    Query.Close;
    Query.SQL.Text := 'Insert into statss(id_modem, date, mac_ap,signal_level, time, status) values('+
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

procedure TMySyncThread.PutToMySQL_AP;
begin
  with form1 do
  begin
    Query.Close;
    Query.SQL.Text := 'Insert into stats_ap(id_modem, date, signal_level, time, loadavg, memfree, rx_octets_eth0, tx_octets_eth0) values('+
            IntToStr(id_modem_statss_local)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local))+','+
            QuotedStr(IntToStr(sig_lev_statss_local))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local))+','+
            loadavg+','+
            memfree+','+
            rx_octets_eth0+','+
            tx_octets_eth0+
            ')';
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

