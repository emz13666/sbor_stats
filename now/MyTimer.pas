unit MyTimer;

interface
uses Classes, forms, snmpsend, pingsend, asn1util, windows, ADODB,MyUtils, Messages;

type
  TMyTimerThread = class(TThread)
  private
    { Private declarations }
    IfOfflineMore5min: boolean;
    F_IndexInterfaceLTEOk: boolean; //Определили или нет индекс интерфейса LTE. Вначале работы потока - нет. Определяем 1 раз при доступности устройства.
    F_IndexInterfaceLTE: Integer;
    F_level: AnsiString;
    F_AP: AnsiString;
    F_Date: AnsiString;
    F_Time: AnsiString;
    F_time_ping: Integer;
    F_Datetime: TDateTime;
    F_rsrp, F_rsrq, F_sinr: AnsiString;
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
    Procedure DoWork_LTE;
    Procedure DoWork_ping;
    Procedure DoWork_AP_Repeater;
    procedure WriteToForm;
    procedure WriteToForm_lte;
    procedure WriteToForm_ping;
    procedure SaveToLocalDB;
    procedure SaveToLocalDB_LTE;
    procedure SaveToLocalDB_ping;
    procedure WriteToForm_AP;
    procedure SaveToLocalDB_AP;
    procedure UpdateMemoOnForm;
    procedure Execute; override;
  public
    PredvPing: boolean;
    PeriodOprosa: integer;
    PeriodUnreachble: integer;
    f_new: boolean;
    f_nameModem: string;
    f_host: AnsiString;
    f_is_alias: boolean;
    f_host_alias: AnsiString;
    F_IDModem: AnsiString;
    f_idEquipment: AnsiString;
    status_default: byte;
    f_is_access_point: boolean;
    f_is_work_of_ping: boolean;
    f_is_lte: boolean;
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

   s_rsrq_lte='1.3.6.1.4.1.14988.1.1.16.1.1.3';// + '.ifIndexLte' - RSRQ
   s_rsrp_lte='1.3.6.1.4.1.14988.1.1.16.1.1.4';//+ '.ifIndexLte' - RSRP
   s_sinr_lte='1.3.6.1.4.1.14988.1.1.16.1.1.7';//+ + '.ifIndexLte' - SINR

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
       snmp.TargetHost := f_host_alias;
       F_Date := FormatDateTime('dd.mm.yyyy',now);
       F_Time := FormatDateTime('hh:nn:ss',now);

           if f_is_alias and snmp.SendRequest then
           begin
                   IfOfflineMore5min := false;
                   //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
                   f_offline_5min := GetTickCount;
                   F_level:=snmp.Reply.MIBGet(s1);
                   F_AP :=convert_s(snmp.Reply.MIBGet(s4));
                 f_online :='1';

           end
           else begin
                 if not PredvPing then
                 begin
                   F_level:='-100';
                   F_AP :='00:00:00:00:00:00';
                   f_online := '0';
                 end
                 else
                   if not fl_noping then fl := false;
               end;
       snmp.TargetHost := f_host;
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
      Synchronize(UpdateMemoOnForm);
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
       snmp.TargetHost := f_host_alias;
       F_Date := FormatDateTime('dd.mm.yyyy',now);
       F_Time := FormatDateTime('hh:nn:ss',now);

       if f_is_alias and snmp.SendRequest then begin
             //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
             IfOfflineMore5min := false;
             f_offline_5min := GetTickCount;
             F_level:=snmp.Reply.MIBGet(s1_new);
             F_AP :=convert_s(snmp.Reply.MIBGet(s4_new));
             f_online :='1';
       end
       else begin
          if not PredvPing then
          begin
               F_level:='-100';
               F_AP :='00:00:00:00:00:00';
               f_online := '0';
          end
          else
              if not fl_noping then fl := false;
       end;
       snmp.TargetHost := f_host;
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
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
   end;
 end;
end;


procedure TMyTimerThread.DoWork_ping;
begin
 try

   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);
   F_Datetime := now;
   F_time_ping := PingHost(f_host);
   if F_time_ping = -1 then F_time_ping := -100;
   if F_time_ping <>-100 then begin
       IfOfflineMore5min := false;
       f_offline_5min := GetTickCount;
       f_online := '1';
   end
   else begin
     if f_is_alias then F_time_ping := PingHost(f_host_alias);
     if F_time_ping = -1 then F_time_ping := -100;
     if f_is_alias and (F_time_ping<>-100) then begin
       IfOfflineMore5min := false;
       f_offline_5min := GetTickCount;
       f_online := '1';
     end
     else begin
       f_online := '0';
     end;
   end;

   SaveToLocalDB_ping;
   Synchronize(WriteToForm_ping);

 except
   on E : Exception do
   begin
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Error in DoWork_new. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
   end;
 end;
end;

procedure TMyTimerThread.DoWork_AP;
var    fl_noping: boolean;
      // CurrentTick: Cardinal;
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
       //CurrentTick := GetTickCount;
       if snmp.SendRequest then
         begin
//           CurrentTick := GetTickCount - CurrentTick;
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
       Synchronize(UpdateMemoOnForm);
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
  if f_new then
    mib_signal :=  '1.3.6.1.4.1.41112.1.4.7.1.3.1.'+
      IntToStr(mac_part1)+'.'+IntToStr(mac_part2)+'.'+IntToStr(mac_part3)+'.'+
      IntToStr(mac_part4)+'.'+IntToStr(mac_part5)+'.'+IntToStr(mac_part6)
  else
    mib_signal := '1.3.6.1.4.1.14988.1.1.1.2.1.3.'+
      IntToStr(mac_part1)+'.'+IntToStr(mac_part2)+'.'+IntToStr(mac_part3)+'.'+
      IntToStr(mac_part4)+'.'+IntToStr(mac_part5)+'.'+IntToStr(mac_part6)+
      '.5';
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
    Synchronize(UpdateMemoOnForm);
    GlobCritSect.Leave;
   end;
 end;

end;


procedure TMyTimerThread.DoWork_LTE;
var
   fl: boolean;
   fl_noping: boolean;
   i: byte;
const
   ifIndex = '1.3.6.1.2.1.2.2.1.1';
   ifIndexDescr = '1.3.6.1.2.1.2.2.1.2';
begin
 fl := true;
 fl_noping := false;
 try
   if not F_IndexInterfaceLTEOk then begin
   // Сначала надо определить индекс интерфейса LTE. Для этого запросим все 5 интерфейсов и их описания:
       snmp.Query.Clear;
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       for i:=1 to 5 do begin
         snmp.Query.MIBAdd(ifIndex +'.'+IntToStr(i),'',ASN1_NULL);
         snmp.Query.MIBAdd(ifIndexDescr +'.'+IntToStr(i),'',ASN1_NULL);
       end;
       if snmp.SendRequest then
       begin
         i := 1;
         while (i <= 5 )and(copy(snmp.Reply.MIBGet(ifIndexDescr+'.'+IntToStr(i)),1,3)<>'lte') do inc (i);
         if i <= 5 then begin
           F_IndexInterfaceLTEOk := true;
           F_IndexInterfaceLTE := StrToInt(snmp.Reply.MIBGet(ifIndex+'.'+IntToStr(i)));
         end;
       end;
   end;
// Выполняем запрос с учётом найденного индекса (при инициализации потока index=1)
   snmp.Query.Clear;
   snmp.Query.Community:='ubnt_mlink54';
   snmp.Query.PDUType := PDUGetRequest;
   snmp.Query.MIBAdd(s_rsrq_lte+'.'+IntToStr(F_IndexInterfaceLTE),'',ASN1_NULL);
   snmp.Query.MIBAdd(s_rsrp_lte+'.'+IntToStr(F_IndexInterfaceLTE),'',ASN1_NULL);
   snmp.Query.MIBAdd(s_sinr_lte+'.'+IntToStr(F_IndexInterfaceLTE),'',ASN1_NULL);

   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);
   F_Datetime := now;

   if PredvPing then
     if PingHost(f_host)=-1 then begin
       F_rsrp:='-150';
       F_rsrq :='-50';
       F_sinr := '-10';
       fl_noping := true;
      end;

   if snmp.SendRequest then
     begin
       //ArrayIdModems5MinNoPing[StrToInt(F_IDModem)] := 0;
       IfOfflineMore5min := false;
       f_offline_5min := GetTickCount;
       F_rsrp:=snmp.Reply.MIBGet(s_rsrp_lte+'.'+IntToStr(F_IndexInterfaceLTE));
       F_rsrq :=snmp.Reply.MIBGet(s_rsrq_lte+'.'+IntToStr(F_IndexInterfaceLTE));
       F_sinr := snmp.Reply.MIBGet(s_sinr_lte+'.'+IntToStr(F_IndexInterfaceLTE));
       f_online :='1';
     end
     else
     begin
          if not PredvPing then
          begin
               F_rsrp:='-150';
               F_rsrq :='-50';
               F_sinr := '-10';
               f_online := '0';
          end
          else
              if not fl_noping then fl := false;
     end;

    if fl then
    begin
      SaveToLocalDB_LTE;
      Synchronize(WriteToForm_lte);
    end;

 except
   on E : Exception do
   begin
      GlobCritSect.Enter;
      SaveLogToFile(LogFileName,'Error in DoWork_LTE. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
      Synchronize(UpdateMemoOnForm);
      GlobCritSect.Leave;
   end;
 end;
end;

procedure TMyTimerThread.Execute;
var begin_tick, timer_5_min: cardinal;
begin
  { Place thread code here }
  F_IndexInterfaceLTEOk := false;
  F_IndexInterfaceLTE := 1;
  f_offline_5min := GetTickCount;
  timer_5_min := GetTickCount;
  IfOfflineMore5min := false;

  f_lasttickcount_tx := 0;
  f_lasttickcount_rx := 0;
  repeat
     if f_is_ap_repeater  then
       DoWork_AP_Repeater
     else
       if f_is_access_point then
         DoWork_AP
       else
         if f_new then
           DoWork_new
         else
           if f_is_lte then
             DoWork_LTE
           else
             if f_is_work_of_ping then
               DoWork_ping
             else
               DoWork;

     if not (f_is_access_point or f_is_ap_repeater) and f_is_collect_net_stat  then
       if not f_is_lte then
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
         statss_localid_equipment.AsInteger := StrToInt(f_idEquipment);
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
      Synchronize(UpdateMemoOnForm);
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
         stats_ap_localid_equipment.AsInteger := StrToInt(f_idEquipment);
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
        Synchronize(UpdateMemoOnForm);
        GlobCritSect.Leave;
       end;
     end;
end;

procedure TMyTimerThread.SaveToLocalDB_LTE;
begin
  if (F_rsrp='')or(F_rsrq='') then exit;
  if (F_sinr='') then exit;
  GlobCritSect.Enter;
  with form1 do
     try
         if not stats_lte.Active then stats_lte.Active := true;
         stats_lte.Last;
         stats_lte.Insert;
         stats_lteid_equipment.AsInteger := StrToInt(f_idEquipment);
         stats_ltedate.AsString := F_Date;
         stats_ltetime.AsString := F_Time;
         stats_ltedatetime.AsDateTime := F_Datetime;
         stats_ltesignal_rsrp.AsInteger := StrToInt(F_rsrp);
         stats_ltesignal_rsrq.AsInteger := StrToInt(F_rsrq);
         stats_ltesignal_sinr.AsInteger := StrToInt(F_sinr);
         stats_lte.Post;
         GlobCritSect.Leave;
     except
      on E:Exception do
      begin
        SaveLogToFile(LogFileName,'Error in SaveToLocalDB. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
        Synchronize(UpdateMemoOnForm);
        GlobCritSect.Leave;
      end;
     end;
end;

procedure TMyTimerThread.SaveToLocalDB_ping;
begin
  GlobCritSect.Enter;
  with form1 do
     try
         if not stats_ping.Active then stats_ping.Active := true;
         stats_ping.Last;
         stats_ping.Insert;
         stats_pingid_equipment.AsInteger := StrToInt(f_idEquipment);
         stats_pingDate.AsString := F_Date;
         stats_pingTime.AsString := F_Time;
         stats_pingdatetime.AsDateTime := F_Datetime;
         stats_pingtime_ping.AsInteger := F_time_ping;
         stats_ping.Post;
         GlobCritSect.Leave;
     except
      on E:Exception do
      begin
        SaveLogToFile(LogFileName,'Error in SaveToLocalDB_ping. Equipment:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
        Synchronize(UpdateMemoOnForm);
        GlobCritSect.Leave;
      end;
     end;
end;

procedure TMyTimerThread.UpdateMemoOnForm;
begin
  Form1.Memo1.Lines.LoadFromFile(LogFileName);
  Form1.Memo1.Perform(EM_LINESCROLL,0,Form1.Memo1.Lines.Count-1);
end;

procedure TMyTimerThread.WriteToForm;
begin
  try
   if not Form1.RxTrayIcon1.Visible then
    Form1.Label4.Caption:=IntToStr(Form1.statss_local.RecordCount);
  except
   on E:Exception do begin
    SaveLogToFile(LogFileName,'Error in WriteToForm. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
    UpdateMemoOnForm;
   end;
  end;
end;

procedure TMyTimerThread.WriteToForm_AP;
begin
  try
    if not Form1.RxTrayIcon1.Visible then
      Form1.Label5.Caption:=IntToStr(Form1.stats_ap_local.RecordCount);
  except
   on E:Exception do begin
      SaveLogToFile(LogFileName,'Ошибка в WriteToForm_AP. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
      UpdateMemoOnForm;
   end;
  end;
end;

procedure TMyTimerThread.WriteToForm_lte;
begin
  try
   if not Form1.RxTrayIcon1.Visible then
    if Form1.stats_lte.Active then Form1.Label9.Caption:=IntToStr(Form1.stats_lte.RecordCount);
  except
   on E:Exception do begin
    SaveLogToFile(LogFileName,'Error in WriteToForm_lte. Modem:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
    UpdateMemoOnForm;
   end;
  end;
end;

procedure TMyTimerThread.WriteToForm_ping;
begin
  try
   if not Form1.RxTrayIcon1.Visible then
    if Form1.stats_ping.Active then Form1.lblCountPing.Caption:=IntToStr(Form1.stats_ping.RecordCount);
  except
   on E:Exception do begin
    SaveLogToFile(LogFileName,'Error in WriteToForm_ping. Equipment:'+f_nameModem+' ('+E.ClassName+': '+E.Message+')');
    UpdateMemoOnForm;
   end;
  end;
end;

end.

