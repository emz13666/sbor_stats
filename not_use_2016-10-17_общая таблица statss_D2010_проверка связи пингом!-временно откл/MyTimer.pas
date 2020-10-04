unit MyTimer;

interface
uses Classes, forms,snmpsend, pingsend, asn1util, windows;

type
  TMyTimerThread = class(TThread)
  private
    { Private declarations }
    F_level: AnsiString;
    F_AP: AnsiString;
    F_Date: AnsiString;
    F_Time: AnsiString;
    f_online: AnsiString;
  protected
//    procedure GetSignalSSH;
    Procedure DoWork;
    Procedure DoWork_new;//for new mibs
    Procedure DoWork_AP;
    procedure WriteToForm;
    procedure SaveToLocalDB;
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
   s1_ap='1.2.840.10036.1.1.1.1.5';



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
   fl_noping,fl: boolean;
   snmp : TSNMPSend;
begin
   snmp := tsnmpsend.Create;
   snmp.TargetHost := f_host;
   snmp.Query.Clear;
   snmp.Timeout := 7000;
 fl := true;
 fl_noping := false;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4,'',ASN1_NULL);

   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);

   if PingHost(f_host)=-1 then begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
       fl_noping := true;
   end;
   if snmp.SendRequest then  begin
           F_level:=snmp.Reply.MIBGet(s1);
           F_AP :=convert_s(snmp.Reply.MIBGet(s4));
         f_online :='1';
       end
       else
         if not fl_noping then fl := false;
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
   fl_noping, fl: boolean;
   snmp : TSNMPSend;
begin
   snmp := tsnmpsend.Create;
   snmp.TargetHost := f_host;
   snmp.Query.Clear;
   snmp.Timeout := 7000;
 fl := true;
 fl_noping := false;
 try
       snmp.Query.Community:='ubnt_mlink54';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1_new,'',ASN1_NULL);
       snmp.Query.MIBAdd(s4_new,'',ASN1_NULL);


   F_Date := FormatDateTime('dd.mm.yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);

   if PingHost(f_host)=-1 then begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
       fl_noping := true;
   end;
   if snmp.SendRequest then
         begin
           F_level:=snmp.Reply.MIBGet(s1_new);
           F_AP :=convert_s(snmp.Reply.MIBGet(s4_new));
           f_online :='1';
         end
         else
           if not fl_noping then fl := false;
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
    fl_noping: boolean;
begin
   snmp := tsnmpsend.Create;
   snmp.TargetHost := f_host;
   snmp.Query.Clear;
   snmp.Timeout := 7000;
  f_online := '1';
  fl_noping := false;
  F_Date := FormatDateTime('dd.mm.yyyy',now);
  F_Time := FormatDateTime('hh:nn:ss',now);
       snmp.Query.Community:='inspector';
       snmp.Query.PDUType := PDUGetRequest;
       snmp.Query.MIBAdd(s1_ap,'',ASN1_NULL);

     try
      if PingHost(f_host)=-1 then begin
           F_level:='-100';
           F_AP :='00:00:00:00:00:00';
           f_online := '0';
           fl_noping := true;
       end;
       if snmp.SendRequest then
         begin
           F_AP:=snmp.Reply.MIBGet(s1_ap);
           F_AP := Trim(F_AP);
           if fl_noping then F_level := '-90' else F_level := IntToStr(-1*(65+random(7)));
         end
         else begin
           if not fl_noping then F_level := '-95' else F_level:='-100';
           F_AP :='00:00:00:00:00:00';
           f_online := '0';
          end;


     finally
       FreeAndNil(snmp);
     end;

      Synchronize(SaveToLocalDB);
      Synchronize(WriteToForm)
end;

procedure TMyTimerThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }

  repeat
      if f_is_access_point then
        DoWork_AP
      else
        if f_new then  DoWork_new    else DoWork;

    //sleep 10 sec
    begin_tick := gettickcount;
    while GetTickCount - begin_tick < 10000 do
      if not Terminated then sleep(10) else break;
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

end.

