unit SyncThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util, ADODB, MyUtils, Messages;

type
  TMySyncThread = class(TThread)
  private
    { Private declarations }
    rec_count_local_statss,rec_count_local_statss_ap,
    rec_count_local_stats_lte, rec_count_local_stats_ping : longint;
    id_statss_local, id_modem_statss_local,
    id_statss_local_ap, id_modem_statss_local_ap,
    id_equip_statss_local, id_equip_statss_local_ap,
    id_equipment_lte, id_equipment_ping : longint;
    rsrq, rsrp, sinr, time_ping: integer;
    loadavg, memfree: AnsiString;
    flag_10minut: boolean;
    rx_octets_eth0, tx_octets_eth0: AnsiString;
    mac_ap_statss_local: AnsiString;
    date_statss_local, time_statss_local: TDateTime;
    date_statss_local_ap, time_statss_local_ap: TDateTime;
    datetime_lte, date_lte, time_lte: TDateTime;
    datetime_ping, date_ping, timeOfPing: TDateTime;
    sig_lev_statss_local, f_online_statss_local, f_status,
    sig_lev_statss_local_ap, f_online_statss_local_ap: integer;
    AQuery: TADOQuery;
    AConn: TADOConnection;
  protected
    Procedure DoWork;
    Procedure DoWork_ap;
    Procedure DoWork_lte;
    Procedure DoWork_ping;
    procedure GetCountLocalStatss;
    procedure GetCountLocalStatss_ap;
    procedure GetCountLocalStatss_lte;
    procedure GetCountLocalStatss_ping;
    procedure GetStatss_local;
    procedure GetStats_ap_local;
    procedure GetStats_lte_local;
    procedure GetStats_ping_local;
    procedure PutToMySQL;
    procedure PutToMySQL_AP;
    procedure PutToMySQL_LTE;
    procedure PutToMySQL_ping;
    procedure DeleteFromStatsLocal;
    procedure DeleteFromStatsLocal_ap;
    procedure DeleteFromStatsLocal_lte;
    procedure DeleteFromStatsLocal_ping;
    procedure UpdateMemoOnForm;
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  end;

var flag_ok, flag_ok_ap, flag_ok_lte, flag_ok_ping: boolean;


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
 if Terminated then exit;
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
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
  end;
 end;
end;

procedure TMySyncThread.DeleteFromStatsLocal_ap;
begin
 if Terminated then exit;
 GlobCritSect.Enter;
 try
    Form1.stats_ap_local.First;
    if Form1.stats_ap_local.Locate('id',id_statss_local_ap,[]) then begin
      Form1.stats_ap_local.Delete;
    end;
    GlobCritSect.Leave;
 except
  on E:Exception do
  begin
    SaveLogToFile(LogFileName,'Error in DeleteFromStatsLocal_ap. id_statss_local:'+IntTostr(id_statss_local)+' ('+E.ClassName+': '+E.Message+')');
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
  end;
 end;
end;

procedure TMySyncThread.DeleteFromStatsLocal_lte;
begin
 if Terminated then exit;
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
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
  end;
 end;
end;

procedure TMySyncThread.DeleteFromStatsLocal_ping;
begin
 if Terminated then exit;
 GlobCritSect.Enter;
 try
    Form1.stats_ping.First;
    if Form1.stats_ping.Locate('id',id_statss_local,[]) then begin
      Form1.stats_ping.Delete;
    end;
    GlobCritSect.Leave;
 except
  on E:Exception do
  begin
    SaveLogToFile(LogFileName,'Error in DeleteFromStatsLocal_ping. id:'+IntTostr(id_statss_local)+' ('+E.ClassName+': '+E.Message+')');
    Synchronize(UpdateMemoOnForm);
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
  if Terminated then exit;
  t1 := GetTickCount;
  GetCountLocalStatss;
  while (rec_count_local_statss>0)and(GetTickCount-t1 < 5000) do
    begin
       GetStatss_local;
       // закомментировано для отладки
       PutToMySQL;
       if flag_ok then DeleteFromStatsLocal;
       GetCountLocalStatss;
        if Terminated then Break;
    end;
end;


procedure TMySyncThread.DoWork_ap;
var t1: cardinal;
begin
 if Terminated then exit;
  t1 := GetTickCount;
  GetCountLocalStatss_ap;
  while (rec_count_local_statss_ap>0)and(GetTickCount-t1 < 5000) do
    begin
       if Terminated then Break;
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
  if Terminated then Exit;
  t1 := GetTickCount;
  GetCountLocalStatss_lte;
  while (rec_count_local_stats_lte>0)and(GetTickCount-t1 < 5000) do
    begin
       if Terminated then Break;
       GetStats_lte_local;
       // закомментировано для отладки
       PutToMySQL_LTE;
       if flag_ok_lte then DeleteFromStatsLocal_lte;
       GetCountLocalStatss_lte;
    end;
end;

procedure TMySyncThread.DoWork_ping;
var t1: cardinal;
begin
  if Terminated then Exit;
  t1 := GetTickCount;
  GetCountLocalStatss_ping;
  while (rec_count_local_stats_ping>0)and(GetTickCount-t1 < 5000) do
    begin
      if Terminated then Break;
       GetStats_ping_local;
       // закомментировано для отладки
       PutToMySQL_ping;
       if flag_ok_ping then DeleteFromStatsLocal_ping;
       GetCountLocalStatss_ping;
    end;
end;

procedure TMySyncThread.Execute;
var begin_tick, begin_tick10min: cardinal;
begin
  { Place thread code here }
  flag_10minut := false;
  repeat
  //  задержка 10 минут - чтобы часто не перезаписывать на диск локальные таблицы
   begin_tick10min := GetTickCount;
    while GetTickCount - begin_tick10min < 10*60*1000 do begin
       if not Terminated then sleep(10) else break;
       DoWork;
       DoWork_ap;
       DoWork_lte;
       DoWork_ping;
       begin_tick := GetTickCount;
        while GetTickCount - begin_tick < 10000 do
          if not Terminated then sleep(10) else break;
    end;
    //если здесь поменять на false - не будет сбрасывать на диск и очищать локальные таблицы.
    flag_10minut := false;
  until Terminated;
end;

procedure TMySyncThread.GetCountLocalStatss;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  try
    if not Form1.statss_local.Active then  Form1.statss_local.Open;
    Form1.statss_local.Last;
    rec_count_local_statss := Form1.statss_local.RecordCount;
    Form1.statss_local.First;
// Чтобы не было утечки памяти - 1 раз в 10 минут если таблица пустая то очищаем её на диске и в памяти:
    if flag_10minut and (rec_count_local_statss=0) then begin
      form1.statss_local.EmptyDataSet;
      form1.statss_local.SaveToFile();
      form1.statss_local.Close;
      form1.statss_local.Open;
        if flag_debug then SaveLogToFile(LogFileName,'rec_count_local_statss=0, EmptyDataSet и SaveToFile');
        if flag_debug then Synchronize(UpdateMemoOnForm);
    end;    (* *)
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
      SaveLogToFile(LogFileName,'Error in GetCountLocalStatss в потоке синхронизации.'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetCountLocalStatss_ap;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  try
    if not Form1.stats_ap_local.Active then Form1.stats_ap_local.Open;
    Form1.stats_ap_local.Last;
    rec_count_local_statss_ap := Form1.stats_ap_local.RecordCount;
    Form1.stats_ap_local.First;

   // Чтобы не было утечки памяти - 1 раз в 10 минут если таблица пустая то очищаем её на диске и в памяти:
    if flag_10minut and (rec_count_local_statss_ap=0) then begin
      form1.stats_ap_local.EmptyDataSet;
      form1.stats_ap_local.SaveToFile();
      form1.stats_ap_local.Close;
      form1.stats_ap_local.Open;
        if flag_debug then SaveLogToFile(LogFileName,'rec_count_local_statss_ap=0, EmptyDataSet и SaveToFile');
        if flag_debug then Synchronize(UpdateMemoOnForm);
    end;
  (*  *)
    GlobCritSect.Leave;
  except
    on E:Exception do
    begin
      SaveLogToFile(LogFileName,'Ошибка при выполнении GetCountLocalStatss_ap в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
    end;
  end;
end;

procedure TMySyncThread.GetCountLocalStatss_lte;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  try
    if not Form1.stats_lte.Active then Form1.stats_lte.Open;
    Form1.stats_lte.Last;
    rec_count_local_stats_lte := Form1.stats_lte.RecordCount;
    Form1.stats_lte.First;
   // Чтобы не было утечки памяти - 1 раз в 10 минут если таблица пустая то очищаем её на диске и в памяти:
    if flag_10minut and (rec_count_local_stats_lte=0) then begin
      form1.stats_lte.EmptyDataSet;
      form1.stats_lte.SaveToFile();
      form1.stats_lte.Close;
      form1.stats_lte.Open;
        if flag_debug then SaveLogToFile(LogFileName,'rec_count_local_statss_lte=0, EmptyDataSet и SaveToFile');
        if flag_debug then Synchronize(UpdateMemoOnForm);
    end;
    (* *)
    GlobCritSect.Leave;
  except
    on E:Exception do
    begin
      SaveLogToFile(LogFileName,'Ошибка при выполнении GetCountLocalStatss_lte в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
    end;
  end;
end;

procedure TMySyncThread.GetCountLocalStatss_ping;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  try
    if not Form1.stats_ping.Active then Form1.stats_ping.Open;
    Form1.stats_ping.Last;
    rec_count_local_stats_ping := Form1.stats_ping.RecordCount;
    Form1.stats_ping.First;
   // Чтобы не было утечки памяти - 1 раз в 10 минут если таблица пустая то очищаем её на диске и в памяти:
    if flag_10minut and (rec_count_local_stats_ping=0) then begin
      form1.stats_ping.EmptyDataSet;
      form1.stats_ping.SaveToFile();
      form1.stats_ping.Close;
      form1.stats_ping.Open;
      flag_10minut := false;
        if flag_debug then SaveLogToFile(LogFileName,'rec_count_local_statss_ping=0, EmptyDataSet и SaveToFile');
        if flag_debug then Synchronize(UpdateMemoOnForm);
    end;
    (* *)
    GlobCritSect.Leave;
  except
    on E:Exception do
    begin
      SaveLogToFile(LogFileName,'Ошибка при выполнении GetCountLocalStatss_ping в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
    end;
  end;
end;

procedure TMySyncThread.GetStatss_local;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  with form1 do
  try
    if not statss_local.Active then statss_local.Open;
    statss_local.Last;
    id_statss_local := statss_localid.AsInteger;
    id_modem_statss_local := statss_localid_modem.AsInteger;
    id_equip_statss_local := statss_localid_equipment.AsInteger;
    sig_lev_statss_local := statss_localsignal_level.AsInteger;
    date_statss_local := statss_localdate.AsDateTime;
    time_statss_local := statss_localtime.AsDateTime;
    mac_ap_statss_local := statss_localmac_ap.AsString;
    f_status := statss_localstatus.AsInteger;
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName,'Ошибка при чтении записи из локальной БД в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetStats_ap_local;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  with form1 do
  try
    if not stats_ap_local.Active then stats_ap_local.Open;
    if rec_count_local_statss_ap=0 then exit;
    stats_ap_local.Last;
    id_statss_local_ap := stats_ap_localid.AsInteger;
    id_modem_statss_local_ap := stats_ap_localid_modem.AsInteger;
    id_equip_statss_local_ap := stats_ap_localid_equipment.AsInteger;
    sig_lev_statss_local_ap := stats_ap_localsignal_level.AsInteger;
    date_statss_local_ap := stats_ap_localDate.AsDateTime;
    time_statss_local_ap := stats_ap_localTime.AsDateTime;
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
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetStats_lte_local;
begin
  if Terminated then Exit;
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

    date_lte := stats_ltedate.AsDateTime;
    time_lte := stats_ltetime.AsDateTime;
    datetime_lte := stats_ltedatetime.AsDateTime;
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName, 'Ошибка при чтении записи из локальной БД_lte в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.GetStats_ping_local;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  with form1 do
  try
    if not stats_ping.Active then stats_ping.Open;
    stats_ping.Last;
    id_statss_local := stats_pingid.AsInteger;
    id_equipment_ping := stats_pingid_equipment.AsInteger;
    time_ping := stats_pingtime_ping.AsInteger;

    date_ping := stats_pingDate.AsDateTime;
    timeOfPing := stats_pingTime.AsDateTime;
    datetime_ping := stats_pingDatetime.AsDateTime;
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName, 'Ошибка при чтении записи из локальной БД_lte в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
   end;
  end;
end;

procedure TMySyncThread.PutToMySQL;
begin
 if Terminated then exit;
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into statss(id_modem, id_equipment, date, mac_ap, signal_level, time, datetime, status) values('+
            IntToStr(id_modem_statss_local)+','+
            IntToStr(id_equip_statss_local)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local))+','+
            QuotedStr(mac_ap_statss_local)+','+
            QuotedStr(IntToStr(sig_lev_statss_local))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local))+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss',date_statss_local+time_statss_local))+','+
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
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
      AQuery.Close;
     end;
    end;

(* 2021-08-18 - убрал обновление здесь. Обновляется статут теперь в потоках ping-ов

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
    end;*)
 finally
   AQuery.Close;
   AConn.Close;
 end;
end;

procedure TMySyncThread.PutToMySQL_AP;
var f_onl: byte;
begin
 if Terminated then exit;
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into stats_ap(id_modem, id_equipment, date, signal_level, time, datetime, loadavg, memfree, rx_octets_eth0, tx_octets_eth0) values('+
            IntToStr(id_modem_statss_local_ap)+','+
            IntToStr(id_equip_statss_local_ap)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_statss_local_ap))+','+
            QuotedStr(IntToStr(sig_lev_statss_local_ap))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_statss_local_ap))+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss',date_statss_local_ap+time_statss_local_ap))+','+
            loadavg+','+
            memfree+','+
            rx_octets_eth0+','+
            tx_octets_eth0+
            ')';
    flag_ok_ap := true;
    try
      AQuery.ExecSQL;

      AQuery.Close;
      if sig_lev_statss_local_ap > -100 then f_onl := 1 else f_onl := 0;
      AQuery.SQL.Text := 'Update modems set online='+Inttostr(f_onl)+' where id_modem='+IntToStr(id_modem_statss_local_ap);
      try
        AQuery.ExecSQL;
      except
        on E:Exception do
        begin
         GlobCritSect.Enter;
         SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
         Synchronize(UpdateMemoOnForm);
         GlobCritSect.Leave;
       end;
     end;


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
 if Terminated then exit;
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into stats_lte(id_equipment, date, time, datetime, signal_rsrp, signal_rsrq, signal_sinr) values('+
            IntToStr(id_equipment_lte)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_lte))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',time_lte))+','+
            QuotedStr(FormatDateTime('yyy-mm-dd hh:nn:ss',datetime_lte))+','+
            IntToStr(rsrp) + ',' +
            IntToStr(rsrq) + ',' +
            IntToStr(sinr) + ')';
    flag_ok_lte := true;
    try
      AQuery.ExecSQL;
    except
     on E:Exception do
     begin
      flag_ok_lte := false;
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
     end;
    end;
 finally
   AQuery.Close;
   AConn.Close;
 end;
end;

procedure TMySyncThread.PutToMySQL_ping;
var
  f_onl: integer;
begin
 if Terminated then exit;
 try
  AQuery.Close;
  AQuery.SQL.Text := 'Insert into stats_ping(id_equipment, date, time, datetime, time_ping) values('+
            IntToStr(id_equipment_ping)+','+
            QuotedStr(FormatDateTime('yyyy-mm-dd',date_ping))+','+
            QuotedStr(FormatDateTime('hh:nn:ss',timeOfPing))+','+
            QuotedStr(FormatDateTime('yyy-mm-dd hh:nn:ss',datetime_ping))+','+
            IntToStr(time_ping) + ')';
    flag_ok_ping := true;
    try
      AQuery.ExecSQL;
    except
     on E:Exception do
     begin
      flag_ok_ping := false;
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
     end;
    end;

    AQuery.Close;
    if time_ping >=0 then f_onl := 1 else f_onl := 0;
    AQuery.SQL.Text := 'Update modems set online='+Inttostr(f_onl)+' where id_equipment='+IntToStr(id_equipment_ping);
    try
      AQuery.ExecSQL;
    except
     on E:Exception do
     begin
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке синхронизации'+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
     end;
    end;

 finally
   AQuery.Close;
   AConn.Close;
 end;
end;

procedure TMySyncThread.UpdateMemoOnForm;
begin
  if Terminated then exit;
  Form1.Memo1.Lines.LoadFromFile(LogFileName);
  Form1.Memo1.Perform(EM_LINESCROLL,0,Form1.Memo1.Lines.Count-1);
end;

end.

