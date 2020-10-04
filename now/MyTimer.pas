unit MyTimer;

interface
uses Classes, forms, snmpsend, pingsend, asn1util, windows, ADODB,MyUtils;

type
  TMyTimerThread = class(TThread)
  private
    { Private declarations }
    IfOfflineMore5min: boolean;
    F_level: AnsiString;
    F_AP: AnsiString;
    F_Date: AnsiString;
    F_Time: AnsiString;
    f_online: AnsiString;
    f_offline_5min: Cardinal;
    f_loadavg: AnsiString;
    f_memfree: AnsiString;
    f_rx_octets, f_rx_octets_eth0, f_last_rx_octets: AnsiString;
    f_tx_octets, f_tx_octets_eth0, f_last_tx_octets: AnsiString;
    f_lasttickcount_tx, f_lasttickcount_rx: cardinal;
    snmp : TSNMPSend;
  protected
    Procedure DoWork;
    Procedure DoWork_new;//for new mibs
    Procedure DoWork_AP;
    Procedure DoWork_AP_Repeater;
    procedure WriteToForm;
    procedure SaveToLocalDB;
    procedure WriteToForm_AP;
    procedure SaveToLocalDB_AP;
    procedure Execute; override;
  public
    PredvPing: boolean;
    PeriodOprosa: integer;
    PeriodUnreachble: integer;
    f_new: boolean;
    f_nameModem: string;
    f_host: AnsiString;
    F_IDModem: AnsiString;
    status_default: byte;
    f_is_access_point: boolean;
    f_is_ap_repeater: boolean;
    f_is_collect_net_stat: boolean;
    F_mac_wds_peer: string;
    f_firmware_thread: string;
    constructor Create(CreateSuspended: Boolean; AFHost: AnsiString; AFTimeoutSnmp: integer);
    destructor Destroy; override;
  end;



const
   s1 = '1.3.6.1.4.1.14988.1.1.1.1.1.4.5';//Signal strength, dBm
   s4 = '1.3.6.1.4.1.14988.1.1.1.1.1.6.5';//ap_mac_address
   s1_new = '1.3.6.1.4.1.41112.1.4.5.1.5.1';//Signal strength, dBm
   s4_new = '1.3.6.1.4.1.41112.1.4.5.1.4.1';//ap_mac_address
 //  bs1 = '00:27:22:8C:4F:3D';
  // bs2 = '00:27:22:8C:50:8B';
//   bs3 = 'DC:9F:DB:98:3F:47'; //'1.3.6.1.4.1.14988.1.1.1.2.1.3.  220.159.219.152.63.71.  5';
 (*  bs3 = 'DC:9F:DB:98:40:76';  //'1.3.6.1.4.1.14988.1.1.1.2.1.3. 220.159.219.152.64.118. 5';
   bs4 = '00:27:22:8C:4F:2C';
   bs5 = 'DC:9F:DB:0C:B6:4C';
   bs6 = 'DC:9F:DB:08:B7:F1';*)
  (* ss1 = '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.79.61.5';
   ss2 = '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.80.139.5';
   ss3 = '1.3.6.1.4.1.14988.1.1.1.2.1.3.220.159.219.152.64.118.5';
   ss4 = '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.79.44.5';
   ss5 = '1.3.6.1.4.1.14988.1.1.1.2.1.3.220.159.219.12.182.76.5';
   ss6 = '1.3.6.1.4.1.14988.1.1.1.2.1.3.220.159.219.8.183.241.5';*)
   s1_ap='1.2.840.10036.1.1.1.1.5';//mac_address
   s2_ap_loadavg='1.3.6.1.4.1.10002.1.1.1.4.2.1.3.1'; //loadavg 1 minute
   s3_ap_memfree='1.3.6.1.4.1.10002.1.1.1.1.2.0';//memfree
   s4_rx_octets_eth0='1.3.6.1.2.1.2.2.1.10.2';//eth0: The total number of octets received on the interface, including framing characters.
   s5_tx_octets_eth0='1.3.6.1.2.1.2.2.1.16.2';//eth0: The total number of octets transmitted out of the interface, including framing characters.



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

{ TMyTimerThread }


function convert_s(const s: AnsiString):AnsiString;
var i: byte;
    ch: Ansichar;
begin
  if s='' then Result := ''
  else
  begin
    Result := '';
    for i:=1 to Length(s)-1 do
    begin
    ch := s[i];
    Result := Result+IntToHex(ord(ch),2)+':';
    end;
    ch := s[Length(s)];
    Result := Result+IntToHex(ord(ch),2);
  end;
end;

constructor TMyTimerThread.Create(CreateSuspended: Boolean; AFHost: AnsiString; AFTimeoutSnmp: integer);
begin
  inherited Create(CreateSuspended);
  f_host :=AFHost;
  snmp := tsnmpsend.Create;
  snmp.TargetHost := f_host;
  snmp.Timeout := AFTimeoutSnmp*1000;
end;

destructor TMyTimerThread.Destroy;
begin
  FreeAndNil(snmp);
  inherited;
end;

procedure TMyTimerThread.DoWork;
var
   fl: boolean;
   fl_noping: boolean;
begin
 snmp.Query.Clear;
 fl := true;
 fl_noping := false;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4,'',ASN1_NULL);
      F_Date := FormatDateTime('dd.mm.yyyy',now);
      F_Time := FormatDateTime('hh:nn:ss',now);
    if PredvPing then
     if PingHost(f_host)=-1 then begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
       fl_noping := true;
      end;

   if snmp.SendRequest then
     begin
         IfOfflineMore5min := false;
         //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
         f_offline_5min := GetTickCount;
         F_level:=snmp.Reply.MIBGet(s1);
         F_AP :=convert_s(snmp.Reply.MIBGet(s4));
       f_online :='1';
     end
     else
     begin
       if not PredvPing then
       begin
         F_level:='-100';
         F_AP :='00:00:00:00:00:00';
         f_online := '0';
       end
       else
         if not fl_noping then fl := false;
     end;
    if fl then
    begin
      SaveToLocalDB;
      Synchronize(WriteToForm);
    end;
 except
    on E : Exception do
    begin
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Error in DoWork. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
    end;
 end;
end;

procedure TMyTimerThread.DoWork_new;
var
   fl: boolean;
   fl_noping: boolean;
begin
 snmp.Query.Clear;
 fl := true;
 fl_noping := false;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1_new,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4_new,'',ASN1_NULL);


   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);

   if PredvPing then
     if PingHost(f_host)=-1 then begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
       fl_noping := true;
      end;

   if snmp.SendRequest then
     begin
       //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
       IfOfflineMore5min := false;
       f_offline_5min := GetTickCount;
       F_level:=snmp.Reply.MIBGet(s1_new);
       F_AP :=convert_s(snmp.Reply.MIBGet(s4_new));
       f_online :='1';
     end
     else
     begin
       if not PredvPing then
       begin
         F_level:='-100';
         F_AP :='00:00:00:00:00:00';
         f_online := '0';
       end
       else
        if not fl_noping then fl := false;
     end;
    if fl then
    begin
      SaveToLocalDB;
      Synchronize(WriteToForm);
    end;

 except
   on E : Exception do
   begin
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Error in DoWork_new. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
   end;
 end;
end;


procedure TMyTimerThread.DoWork_AP;
var    fl_noping: boolean;
begin
   snmp.Query.Clear;
   f_online := '1';
   fl_noping := false;
   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1_ap,'',ASN1_NULL);
       snmp.Query.MIBAdd(s2_ap_loadavg,'',ASN1_NULL);
       snmp.Query.MIBAdd(s3_ap_memfree,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4_rx_octets_eth0,'',ASN1_NULL);
       snmp.Query.MIBAdd(s5_tx_octets_eth0,'',ASN1_NULL);
     try
       if PredvPing then
           if PingHost(f_host)=-1 then begin
           F_level:='-100';
           F_AP :='00:00:00:00:00:00';
           f_online := '0';
           fl_noping := true;
       end;

       if snmp.SendRequest then
         begin
           //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
           IfOfflineMore5min:=false;
           f_offline_5min := GetTickCount;

           F_AP:=snmp.Reply.MIBGet(s1_ap);
           F_AP := Trim(F_AP);
           F_level := IntToStr(-1*(65+random(7)));
           f_loadavg := trim(snmp.Reply.MIBGet(s2_ap_loadavg));
           f_memfree := trim(snmp.Reply.MIBGet(s3_ap_memfree));
           f_rx_octets := trim(snmp.Reply.MIBGet(s4_rx_octets_eth0));
           f_tx_octets := trim(snmp.Reply.MIBGet(s5_tx_octets_eth0));

           if f_lasttickcount_tx > 0 then
              f_tx_octets_eth0 := IntToStr(Round((StrToInt64(f_tx_octets)-StrToInt64(f_last_tx_octets))*1000/(f_offline_5min - f_lasttickcount_tx)))
           else
              f_tx_octets_eth0 := '0';

           if f_lasttickcount_rx > 0 then
             f_rx_octets_eth0 := IntToStr(Round((StrToInt64(f_rx_octets)-StrToInt64(f_last_rx_octets))*1000/(f_offline_5min-f_lasttickcount_rx)))
           else
             f_rx_octets_eth0 := '0';

           if not (f_tx_octets = f_last_tx_octets) then f_lasttickcount_tx:= f_offline_5min;
           if not (f_rx_octets = f_last_rx_octets) then f_lasttickcount_rx:= f_offline_5min;
           f_last_rx_octets := f_rx_octets;
           f_last_tx_octets := f_tx_octets;
           if PredvPing then  if fl_noping then F_level := '-90' else F_level := IntToStr(-1*(65+random(7)));
         end
         else begin
           if not PredvPing then begin
             F_level:='-100';
             F_AP :='00:00:00:00:00:00';
             f_online := '0';
             f_loadavg :='-1';
             f_memfree := '0';
             f_rx_octets_eth0 := '0';
             f_tx_octets_eth0 := '0';
           end
           else begin
             if not fl_noping then F_level := '-95' else F_level:='-100';
             F_AP := '00:00:00:00:00:00';
             f_online := '0';
           end;
         end;
        SaveToLocalDB_AP;
        Synchronize(WriteToForm_AP);
     except
      on E : Exception do
      begin
       GlobCritSect.Enter;
       SaveLogToFile(LogFileName,'Error in DoWork_AP. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
       GlobCritSect.Leave;
      end;
     end;
end;

function HexToInt(Str : string): integer;
var i, r : integer;
begin
  val('$'+Trim(Str),r, i);
  if i<>0 then HexToInt := -1 {была ошибка в написании числа}
  else HexToInt := r;
end;

procedure TMyTimerThread.DoWork_AP_Repeater;
//mib для уровня сигнала: мак-адрес в десятичном виде
//'1.3.6.1.4.1.14988.1.1.1.2.1.3.  220.159.219.152.63.71  .5';
var
   fl, fl_incorrect_wds_peer: boolean;
   fl_noping: boolean;
   mib_signal: AnsiString;
   mac_part1, mac_part2, mac_part3, mac_part4, mac_part5, mac_part6:integer;
begin
  mac_part1 := HexToInt(Copy(F_mac_wds_peer,1,2));
  mac_part2 := HexToInt(Copy(F_mac_wds_peer,4,2));
  mac_part3 := HexToInt(Copy(F_mac_wds_peer,7,2));
  mac_part4 := HexToInt(Copy(F_mac_wds_peer,10,2));
  mac_part5 := HexToInt(Copy(F_mac_wds_peer,13,2));
  mac_part6 := HexToInt(Copy(F_mac_wds_peer,16,2));
  fl_incorrect_wds_peer := false;
  if (mac_part1<0)or(mac_part2<0)or(mac_part3<0)or(mac_part4<0)or(mac_part5<0)or(mac_part6<0) then
  begin
    GlobCritSect.Enter;
    SaveLogToFile(LogFileName,'Incorrect mac_wds_peer into modem: '+f_nameModem+' (mac_wds_peer='+F_mac_wds_peer+')');
    GlobCritSect.Leave;
    fl_incorrect_wds_peer := true;
  end;

  mib_signal := '1.3.6.1.4.1.14988.1.1.1.2.1.3.'+
    IntToStr(mac_part1)+'.'+IntToStr(mac_part2)+'.'+IntToStr(mac_part3)+'.'+IntToStr(mac_part4)+'.'+IntToStr(mac_part5)+'.'+IntToStr(mac_part6)+'.5';
   snmp.Query.Clear;
 fl := true;
 fl_noping := false;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       if not fl_incorrect_wds_peer then snmp.Query.MIBAdd(mib_signal,'',ASN1_NULL);
       snmp.Query.MIBAdd(s2_ap_loadavg,'',ASN1_NULL);
       snmp.Query.MIBAdd(s3_ap_memfree,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4_rx_octets_eth0,'',ASN1_NULL);
       snmp.Query.MIBAdd(s5_tx_octets_eth0,'',ASN1_NULL);
       F_Date := FormatDateTime('dd.mm.yyyy',now);
       F_Time := FormatDateTime('hh:nn:ss',now);
   if PredvPing then
     if PingHost(f_host)=-1 then begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
       fl_noping := true;
      end;

   if snmp.SendRequest then
     begin
         //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
         IfOfflineMore5min := false;
         f_offline_5min := GetTickCount;
         if fl_incorrect_wds_peer then F_level:=IntToStr(-1*(65+random(7)))
           else  F_level := snmp.Reply.MIBGet(mib_signal);
           F_AP := F_mac_wds_peer;
           f_loadavg := trim(snmp.Reply.MIBGet(s2_ap_loadavg));
           f_memfree := trim(snmp.Reply.MIBGet(s3_ap_memfree));
           f_rx_octets := trim(snmp.Reply.MIBGet(s4_rx_octets_eth0));
           f_tx_octets := trim(snmp.Reply.MIBGet(s5_tx_octets_eth0));

           if f_lasttickcount_tx > 0 then
              f_tx_octets_eth0 := IntToStr(Round((StrToInt64(f_tx_octets)-StrToInt64(f_last_tx_octets))*1000/(f_offline_5min - f_lasttickcount_tx)))
           else
              f_tx_octets_eth0 := '0';

           if f_lasttickcount_rx > 0 then
             f_rx_octets_eth0 := IntToStr(Round((StrToInt64(f_rx_octets)-StrToInt64(f_last_rx_octets))*1000/(f_offline_5min-f_lasttickcount_rx)))
           else
             f_rx_octets_eth0 := '0';

           if not (f_tx_octets = f_last_tx_octets) then f_lasttickcount_tx:= f_offline_5min;
           if not (f_rx_octets = f_last_rx_octets) then f_lasttickcount_rx:= f_offline_5min;
           f_last_rx_octets := f_rx_octets;
           f_last_tx_octets := f_tx_octets;
           f_online :='1';
     end
     else
     begin
       if not PredvPing then
       begin
         F_level:='-100';
         F_AP :='00:00:00:00:00:00';
         f_online := '0';
       end
       else
         if not fl_noping then fl := false;
     end;
    if fl then
    begin
      SaveToLocalDB;
      SaveToLocalDB_AP;
      Synchronize(WriteToForm);
      Synchronize(WriteToForm_AP);
    end;
 except
   on E:Exception do
   begin
    GlobCritSect.Enter;
    SaveLogToFile(LogFileName,'Error in DoWork_AP_Repeater. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
   end;
 end;

end;


procedure TMyTimerThread.Execute;
var begin_tick, timer_5_min: cardinal;
begin
  { Place thread code here }
  f_offline_5min := GetTickCount;
  timer_5_min := GetTickCount;
  IfOfflineMore5min := false;

  f_lasttickcount_tx := 0;
  f_lasttickcount_rx := 0;
  repeat
     if f_is_ap_repeater  then DoWork_AP_Repeater
     else
      if f_is_access_point then
        DoWork_AP
      else
        if f_new then
          DoWork_new
        else
          DoWork;
     if not (f_is_access_point or f_is_ap_repeater) and f_is_collect_net_stat  then
       DoWork_AP;

    //если устройство офлайн больше 5 минут то мониторить раз в 1 минуту
    //sleep 60 sec
    if GetTickCount - f_offline_5min > 300000 then IfOfflineMore5min := true;

    if IfOfflineMore5min then
    begin
       begin_tick := gettickcount;
       while GetTickCount - begin_tick < PeriodUnreachble*1000 do
         if not Terminated then sleep(10) else break;
    end
     else
     begin
       //sleep 10 sec
       begin_tick := gettickcount;
       while GetTickCount - begin_tick < PeriodOprosa*1000 do
         if not Terminated then sleep(10) else break;
     end;
  until Terminated;
end;

procedure TMyTimerThread.SaveToLocalDB;
begin
  if (F_AP='') then exit;
  if F_level='' then exit;
  GlobCritSect.Enter;
  with form1 do
     try
         if not statss_local.Active then statss_local.Active := true;
         statss_local.Last;
         statss_local.Insert;
         statss_localid_modem.AsInteger := StrToInt(F_IDModem);
         statss_localmac_ap.AsString := F_AP;
         statss_localdate.AsString := F_Date;
         statss_localtime.AsString := F_Time;
         statss_localsignal_level.AsInteger := strtoint(F_level);
         statss_localstatus.AsInteger := status_default;
         statss_local.Post;
         GlobCritSect.Leave;
     except
      on E:Exception do
      begin
      SaveLogToFile(LogFileName,'Error in SaveToLocalDB. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
      GlobCritSect.Leave;
      end;
     end;
end;


procedure TMyTimerThread.SaveToLocalDB_AP;
begin
  GlobCritSect.Enter;
  with form1 do
     try
         if not stats_ap_local.Active then stats_ap_local.Active := true;
         stats_ap_local.Last;
         stats_ap_local.Insert;
         stats_ap_localid_modem.AsInteger := StrToInt(F_IDModem);
         stats_ap_localDate.AsAnsiString := F_Date;
         stats_ap_localTime.AsAnsiString := F_Time;
         if F_level='' then F_level := '-99';
         stats_ap_localsignal_level.AsInteger :=  strtoint(F_level);
         if f_loadavg='' then f_loadavg:='0';
         if f_rx_octets_eth0='' then f_rx_octets_eth0:='0';
         if f_tx_octets_eth0='' then f_tx_octets_eth0:='0';
         if f_memfree='' then f_memfree:='0';

         stats_ap_localloadavg.AsAnsiString := f_loadavg;
         if StrToInt(f_memfree)<0 then f_memfree := '0';
         stats_ap_localmemfree.AsAnsiString := f_memfree;
         if StrToInt64(f_rx_octets_eth0)<0 then f_rx_octets_eth0 := '0';
         if StrToInt64(f_tx_octets_eth0)<0 then f_tx_octets_eth0 := '0';
         stats_ap_localrx_octets_eth0.AsAnsiString := f_rx_octets_eth0;
         stats_ap_localtx_octets_eth0.AsAnsiString := f_tx_octets_eth0;
         stats_ap_local.Post;
         GlobCritSect.Leave;
     except
       on E:Exception do
       begin
        SaveLogToFile(LogFileName,'Ошибка в SaveToLocalDB_AP. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
        GlobCritSect.Leave;
       end;
     end;
end;

procedure TMyTimerThread.WriteToForm;
begin
  try
   if not Form1.RxTrayIcon1.Visible then
    Form1.Label4.Caption:=IntToStr(Form1.statss_local.RecordCount);
  except
   on E:Exception do
    SaveLogToFile(LogFileName,'Error in WriteToForm. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
  end;
end;

procedure TMyTimerThread.WriteToForm_AP;
begin
  try
    if not Form1.RxTrayIcon1.Visible then
      Form1.Label5.Caption:=IntToStr(Form1.stats_ap_local.RecordCount);
  except
   on E:Exception do
      SaveLogToFile(LogFileName,'Ошибка в WriteToForm_AP. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
  end;
end;

end.

