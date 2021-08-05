unit SyncThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util, ADODB, MyUtils;

type
  TMySyncThread = class(TThread)
  private
    { Private declarations }
    rec_count_local_statss,rec_count_local_statss_ap,
    rec_count_local_stats_lte : longint;
    id_statss_local, id_modem_statss_local,
    id_equipment_lte : longint;
    rsrq, rsrp, sinr: integer;
    loadavg, memfree: AnsiString;
    rx_octets_eth0, tx_octets_eth0: AnsiString;
    mac_ap_statss_local: AnsiString;
    date_statss_local, datetime_lte, time_statss_local: TDateTime;
    sig_lev_statss_local, f_online_statss_local,f_status: integer;
    AQuery: TADOQuery;
    AConn: TADOConnection;
  protected
    Procedure DoWork;
    Procedure DoWork_ap;
    Procedure DoWork_lte;
    procedure GetCountLocalStatss;
    procedure GetCountLocalStatss_ap;
    procedure GetCountLocalStatss_lte;
    procedure GetStatss_local;
    procedure GetStats_ap_local;
    procedure GetStats_lte_local;
    procedure PutToMySQL;
    procedure PutToMySQL_AP;
    procedure PutToMySQL_LTE;
    procedure DeleteFromStatsLocal;
    procedure DeleteFromStatsLocal_ap;
    procedure DeleteFromStatsLocal_lte;
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  end;

var flag_ok, flag_ok_ap: boolean;


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


constructor TMySyncThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  AQuery := TADOQuery.Create(Application);
  AConn := TADOConnection.Create(Application);
  AConn.ConnectionString := 'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql_ubiquiti';
  AConn.Provider := 'MSDASQL.1';
  AConn.LoginPrompt := false;
  AQuery.Connection := AConn;
  AConn.Close;
end;

procedure TMySyncThread.DeleteFromStatsLocal;
begin
 GlobCritSect.Enter;
 try
    Form1.statss_local.First;
    if Form1.statss_local.Locate('id',id_statss_local,[]) then begin
      Form1.statss_local.Delete;
    end;
    GlobCritSect.Leave;
 except
  on E:Exception do
  begin
    SaveLogToFile(LogFileName,'Error in DeleteFromStatsLocal. id_statss_local:'+IntTostr(id_statss_local)+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
  end;
 end;
end;

procedure TMySyncThread.DeleteFromStatsLocal_ap;
begin
 GlobCritSect.Enter;
 try
    Form1.stats_ap_local.First;
    if Form1.stats_ap_local.Locate('id',id_statss_local,[]) then begin
      Form1.stats_ap_local.Delete;
    end;
    GlobCritSect.Leave;
 except
  on E:Exception do
  begin
    SaveLogToFile(LogFileName,'Error in DeleteFromStatsLocal_ap. id_statss_local:'+IntTostr(id_statss_local)+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
  end;
 end;
end;

procedure TMySyncThread.DeleteFromStatsLocal_lte;
begin
 GlobCritSect.Enter;
 try
    Form1.stats_lte.First;
    if Form1.stats_lte.Locate('id',id_statss_local,[]) then begin
      Form1.stats_lte.Delete;
    end;
    GlobCritSect.Leave;
 except
  on E:Exception do
  begin
    SaveLogToFile(LogFileName,'Error in DeleteFromStatsLocal_lte. id:'+IntTostr(id_statss_local)+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
  end;
 end;
end;

destructor TMySyncThread.Destroy;
begin
   AQuery.Close;AQuery.Connection := nil;
   FreeAndNil(AQuery);
   AConn.Close; FreeAndNil(AQuery);
  inherited;
end;

procedure TMySyncThread.DoWork;
var t1: cardinal;
begin
  t1 := GetTickCount;
  GetCountLocalStatss;
  while (rec_count_local_statss>0)and(GetTickCount-t1 < 15000) do
    begin
       GetStatss_local;
       // закомментировано для отладки
       PutToMySQL;
       if flag_ok then DeleteFromStatsLocal;
       GetCountLocalStatss;
    end;
end;


procedure TMySyncThread.DoWork_ap;
var t1: cardinal;
begin
  t1 := GetTickCount;
  GetCountLocalStatss_ap;
  while (rec_count_local_statss_ap>0)and(GetTickCount-t1 < 15000) do
    begin
       GetStats_ap_local;
       // закомментировано для отладки
       PutToMySQL_ap;
       if flag_ok_ap then DeleteFromStatsLocal_ap;
       GetCountLocalStatss_ap;
    end;
end;

procedure TMySyncThread.DoWork_lte;
var t1: cardinal;
begin
  t1 := GetTickCount;
  GetCountLocalStatss_lte;
  while (rec_count_local_stats_lte>0)and(GetTickCount-t1 < 15000) do
    begin
       GetStats_lte_local;
       // закомментировано для отладки
       PutToMySQL_LTE;
       if flag_ok then DeleteFromStatsLocal_lte;
       GetCountLocalStatss_lte;
    end;
end;

procedure TMySyncThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  repeat
   DoWork;
   DoWork_ap;
   DoWork_lte;
   begin_tick := GetTickCount;
    while GetTickCount - begin_tick < 5000 do
      if not Terminated then sleep(10) else break;
  until Terminated;
end;

procedure TMySyncThread.GetCountLocalStatss;
begin
  GlobCritSect.Enter;
  try
    if not Form1.statss_local.Active then  Form1.statss_local.Open;
    rec_count_local_statss := Form1.statss_local.RecordCount;
    if rec_count_local_statss=0 then begin
      form1.statss_local.EmptyDataSet;
      form1.statss_local.SaveToFile();
      form1.statss_local.Close;
      form1.statss_local.Open;
    end;
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
      SaveLogToFile(LogFileName,'Error in GetCountLocalStatss в потоке синхронизации.'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetCountLocalStatss_ap;
begin
  GlobCritSect.Enter;
  try
    if not Form1.stats_ap_local.Active then Form1.stats_ap_local.Open;
    rec_count_local_statss_ap := Form1.stats_ap_local.RecordCount;
    if rec_count_local_statss_ap=0 then begin
      form1.stats_ap_local.EmptyDataSet;
      form1.stats_ap_local.SaveToFile();
      form1.stats_ap_local.Close;
      form1.stats_ap_local.Open;
    end;
    GlobCritSect.Leave;
  except
    on E:Exception do
    begin
      SaveLogToFile(LogFileName,'Ошибка при выполнении GetCountLocalStatss_ap в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
    end;
  end;
end;

procedure TMySyncThread.GetCountLocalStatss_lte;
begin
  GlobCritSect.Enter;
  try
    if not Form1.stats_lte.Active then Form1.stats_lte.Open;
    rec_count_local_stats_lte := Form1.stats_lte.RecordCount;
    if rec_count_local_stats_lte=0 then begin
      form1.stats_lte.EmptyDataSet;
      form1.stats_lte.SaveToFile();
      form1.stats_lte.Close;
      form1.stats_lte.Open;
    end;
    GlobCritSect.Leave;
  except
    on E:Exception do
    begin
      SaveLogToFile(LogFileName,'Ошибка при выполнении GetCountLocalStatss_lte в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
    end;
  end;
end;

procedure TMySyncThread.GetStatss_local;
begin
  GlobCritSect.Enter;
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
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName,'Ошибка при чтении записи из локальной БД в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetStats_ap_local;
begin
  GlobCritSect.Enter;
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
    if loadavg='' then loadavg:='0';
    if memfree ='' then memfree :='0';
    if rx_octets_eth0='' then rx_octets_eth0:='0';
    if tx_octets_eth0='' then tx_octets_eth0 :='0';
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName, 'Ошибка при чтении записи из локальной БД_ap в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetStats_lte_local;
begin
  GlobCritSect.Enter;
  with form1 do
  try
    if not stats_lte.Active then stats_lte.Open;
    stats_lte.Last;
    id_statss_local := stats_lteid.AsInteger;
    id_equipment_lte := stats_lteid_equipment.AsInteger;
    rsrq := stats_ltesignal_rsrq.AsInteger;
    rsrp := stats_ltesignal_rsrp.AsInteger;
    sinr := stats_ltesignal_sinr.AsInteger;

    date_statss_local := stats_ltedate.AsDateTime;
    time_statss_local := stats_ltetime.AsDateTime;
    datetime_lte := stats_ltedatetime.AsDateTime;
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName, 'Ошибка при чтении записи из локальной БД_lte в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.PutToMySQL;
begin
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into statss(id_modem, date, mac_ap,signal_level, time, status) values('+
            IntToStr(id_modem_statss_local)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local))+','+
            QuotedStr(mac_ap_statss_local)+','+
            QuotedStr(IntToStr(sig_lev_statss_local))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local))+','+
            IntToStr(f_status)+')';
  flag_ok := true;
    try
      AQuery.ExecSQL;
      AQuery.Close;
    except
     on E:Exception do
     begin
      flag_ok := false;
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
      AQuery.Close;
     end;
    end;

    AQuery.Close;
    AQuery.SQL.Text := 'Update modems set online='+Inttostr(f_online_statss_local)+' where id_modem='+IntToStr(id_modem_statss_local);
    flag_ok := true;
    try
      AQuery.ExecSQL;
    except
     on E:Exception do
     begin
      flag_ok := false;
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
     end;
    end;
 finally
   AQuery.Close;
   AConn.Close;
 end;
end;

procedure TMySyncThread.PutToMySQL_AP;
begin
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into stats_ap(id_modem, date, signal_level, time, loadavg, memfree, rx_octets_eth0, tx_octets_eth0) values('+
            IntToStr(id_modem_statss_local)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local))+','+
            QuotedStr(IntToStr(sig_lev_statss_local))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local))+','+
            loadavg+','+
            memfree+','+
            rx_octets_eth0+','+
            tx_octets_eth0+
            ')';
    flag_ok_ap := true;
    try
      AQuery.ExecSQL;
    except
     on E:Exception do
     begin
      flag_ok_ap := false;
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
     end;
    end;
 finally
   AQuery.Close;
   AConn.Close;
 end;
end;

procedure TMySyncThread.PutToMySQL_LTE;
begin
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into stats_lte(id_equipment, date, time, datetime, signal_rsrp, signal_rsrq, signal_sinr) values('+
            IntToStr(id_equipment_lte)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local))+','+
            QuotedStr(FormatDateTime('yyy-mm-dd hh:nn:ss',datetime_lte))+','+
            IntToStr(rsrp) + ',' +
            IntToStr(rsrq) + ',' +
            IntToStr(sinr) + ')';
    flag_ok_ap := true;
    try
      AQuery.ExecSQL;
    except
     on E:Exception do
     begin
      flag_ok_ap := false;
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
     end;
    end;
 finally
   AQuery.Close;
   AConn.Close;
 end;
end;

end.

