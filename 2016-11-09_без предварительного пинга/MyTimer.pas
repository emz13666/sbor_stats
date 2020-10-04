unit MyTimer;

interface
uses Classes, forms,snmpsend,asn1util, windows;

type
  TMyTimerThread = class(TThread)
  private
    { Private declarations }
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
  protected
//    procedure GetSignalSSH;
    Procedure DoWork;
    Procedure DoWork_new;//for new mibs
    Procedure DoWork_AP;
    procedure WriteToForm;
    procedure SaveToLocalDB;
    procedure WriteToForm_AP;
    procedure SaveToLocalDB_AP;
    procedure Execute; override;
  public
    f_new: boolean;
    f_host: AnsiString;
    F_IDModem: AnsiString;
    status_default: byte;
    f_is_access_point: boolean;
  end;



const
   s1 = '1.3.6.1.4.1.14988.1.1.1.1.1.4.5';//Signal strength, dBm
   s4 = '1.3.6.1.4.1.14988.1.1.1.1.1.6.5';//ap_mac_address
   s1_new = '1.3.6.1.4.1.41112.1.4.5.1.5.1';//Signal strength, dBm
   s4_new = '1.3.6.1.4.1.41112.1.4.5.1.4.1';//ap_mac_address
 //  bs1 = '00:27:22:8C:4F:3D';
  // bs2 = '00:27:22:8C:50:8B';
//   bs3 = 'DC:9F:DB:98:3F:47'; //'1.3.6.1.4.1.14988.1.1.1.2.1.3.220.159.219.152.63.71.5';
 (*  bs3 = 'DC:9F:DB:98:40:76';  //'1.3.6.1.4.1.14988.1.1.1.2.1.3.220.159.219.152.64.118.5';
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


procedure TMyTimerThread.DoWork;
var
   fl: boolean;
   snmp : TSNMPSend;
begin
   snmp := tsnmpsend.Create;
   snmp.TargetHost := f_host;
   snmp.Query.Clear;
   snmp.Timeout := 7000;
 fl := true;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4,'',ASN1_NULL);
(*       snmp.Query.MIBAdd(ss1,'',ASN1_NULL);
       snmp.Query.MIBAdd(ss2,'',ASN1_NULL);
       snmp.Query.MIBAdd(ss3,'',ASN1_NULL);
       snmp.Query.MIBAdd(ss4,'',ASN1_NULL);
       snmp.Query.MIBAdd(ss5,'',ASN1_NULL);
       snmp.Query.MIBAdd(ss6,'',ASN1_NULL);
  *)
   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);
   if snmp.SendRequest then
     begin
         f_offline_5min := GetTickCount;
         F_level:=snmp.Reply.MIBGet(s1);
         F_AP :=convert_s(snmp.Reply.MIBGet(s4));
(*       if F_level ='' then
       begin
         F_level := snmp.Reply.MIBGet(ss1);
         F_AP := bs1;
         if F_level ='' then
         begin
           F_level := snmp.Reply.MIBGet(ss2);
           F_AP := bs2;
           if F_level ='' then
           begin
             F_level := snmp.Reply.MIBGet(ss3);
             F_AP := bs3;
             if F_level ='' then
             begin
               F_level := snmp.Reply.MIBGet(ss4);
               F_AP := bs4;
               if F_level ='' then
               begin
                 F_level := snmp.Reply.MIBGet(ss5);
                 F_AP := bs5;
                 if F_level='' then
                 begin
                   F_level := snmp.Reply.MIBGet(ss6);
                   F_AP := bs6;
                   if F_level ='' then  fl := false;
                 end;
               end;
             end;
           end;
         end;
       end;*)
       f_online :='1';
     end
     else
     begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
     end;
    if fl then
    begin
      Synchronize(SaveToLocalDB);
      Synchronize(WriteToForm);
    end;
 finally
    FreeAndNil(snmp);
 end;
end;

procedure TMyTimerThread.DoWork_new;
var
   fl: boolean;
   snmp : TSNMPSend;
begin
   snmp := tsnmpsend.Create;
   snmp.TargetHost := f_host;
   snmp.Query.Clear;
   snmp.Timeout := 7000;
 fl := true;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1_new,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4_new,'',ASN1_NULL);


   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);
   if snmp.SendRequest then
     begin
       f_offline_5min := GetTickCount;
       F_level:=snmp.Reply.MIBGet(s1_new);
       F_AP :=convert_s(snmp.Reply.MIBGet(s4_new));
       f_online :='1';
     end
     else
     begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
     end;
    if fl then
    begin
      Synchronize(SaveToLocalDB);
      Synchronize(WriteToForm);
    end;
 finally
    FreeAndNil(snmp);
 end;
end;


procedure TMyTimerThread.DoWork_AP;
var snmp: TSNMPSend;
begin
   snmp := tsnmpsend.Create;
   snmp.TargetHost := f_host;
   snmp.Query.Clear;
   snmp.Timeout := 7000;
  f_online := '1';
  F_Date := FormatDateTime('dd.mm.yyyy',now);
  F_Time := FormatDateTime('hh:nn:ss',now);
       snmp.Query.Community:='inspector';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1_ap,'',ASN1_NULL);
       snmp.Query.MIBAdd(s2_ap_loadavg,'',ASN1_NULL);
       snmp.Query.MIBAdd(s3_ap_memfree,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4_rx_octets_eth0,'',ASN1_NULL);
       snmp.Query.MIBAdd(s5_tx_octets_eth0,'',ASN1_NULL);
     try
       if snmp.SendRequest then
         begin
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
         end
         else begin
           F_level:='-100';
           F_AP :='00:00:00:00:00:00';
           f_online := '0';
           f_loadavg :='-1';
           f_memfree := '0';
           f_rx_octets_eth0 := '0';
           f_tx_octets_eth0 := '0';
         end;

     finally
       FreeAndNil(snmp);
     end;

      Synchronize(SaveToLocalDB_AP);
      Synchronize(WriteToForm_AP)
end;

procedure TMyTimerThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  f_offline_5min := GetTickCount;
  f_lasttickcount_tx := 0;
  f_lasttickcount_rx := 0;
  repeat
      if f_is_access_point then
        DoWork_AP
      else
        if f_new then  DoWork_new    else DoWork;

    //если устройство офлайн больше 5 минут то мониторить раз в 1 минуту
    //sleep 60 sec
    if GetTickCount - f_offline_5min > 300000 then
    begin
       begin_tick := gettickcount;
       while GetTickCount - begin_tick < 60000 do
         if not Terminated then sleep(10) else break;
     end
     else
     begin
       //sleep 10 sec
       begin_tick := gettickcount;
       while GetTickCount - begin_tick < 10000 do
         if not Terminated then sleep(10) else break;
     end;
  until Terminated;


end;

procedure TMyTimerThread.SaveToLocalDB;
begin
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
     except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении SaveToLocalDB в потоке сбора статистики');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
     end;
end;


procedure TMyTimerThread.SaveToLocalDB_AP;
begin
  with form1 do
     try
         if not stats_ap_local.Active then stats_ap_local.Active := true;
         stats_ap_local.Last;
         stats_ap_local.Insert;
         stats_ap_localid_modem.AsInteger := StrToInt(F_IDModem);
         stats_ap_localDate.AsAnsiString := F_Date;
         stats_ap_localTime.AsAnsiString := F_Time;
         stats_ap_localsignal_level.AsInteger :=  strtoint(F_level);
         stats_ap_localloadavg.AsAnsiString := f_loadavg;
         stats_ap_localmemfree.AsAnsiString := f_memfree;
         stats_ap_localrx_octets_eth0.AsAnsiString := f_rx_octets_eth0;
         stats_ap_localtx_octets_eth0.AsAnsiString := f_tx_octets_eth0;
         stats_ap_local.Post;
     except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении SaveToLocalDB_AP в потоке сбора статистики');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
     end;
end;

procedure TMyTimerThread.WriteToForm;
begin
  try
//    Form1.Memo1.Lines.Add(F_DateTime+'     '+f_host+'      '+F_level+' dB       mac_ap: '+F_AP);
//    Form1.Label2.Caption := IntToStr(form1.Memo1.Lines.Count);
    Form1.Label4.Caption:=IntToStr(Form1.statss_local.RecordCount);
  except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении WriteToForm в потоке сбора статистики');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TMyTimerThread.WriteToForm_AP;
begin
  try
//    Form1.Memo1.Lines.Add(F_DateTime+'     '+f_host+'      '+F_level+' dB       mac_ap: '+F_AP);
//    Form1.Label2.Caption := IntToStr(form1.Memo1.Lines.Count);
    Form1.Label5.Caption:=IntToStr(Form1.stats_ap_local.RecordCount);
  except
      mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении WriteToForm в потоке сбора статистики');
      mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;

end;

end.

