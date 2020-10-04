unit MyTimer;

interface
uses Classes, forms,snmpsend,asn1util;

type
  TMyTimerThread = class(TThread)
  private
    { Private declarations }
    F_level: string;
    F_AP: string;
    F_DateTime, F_Date: string;
    F_Day, F_Month, F_year, F_Time: string;
    f_online: string;

  protected
    Procedure DoWork;
    Procedure DoWork_AP;
//    procedure GetSignalSSH;
    Procedure AddToBDB;
    procedure WriteToForm;
    procedure SaveToLocalDB;
    procedure Execute; override;
  public
    f_host: string;
    F_IDModem: string;
    status_default: byte;
    f_is_access_point: boolean;
  end;



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
function convert_s(s: string):string;
var i: byte;
    ch: char;
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

procedure TMyTimerThread.AddToBDB;
begin
  Synchronize(SaveToLocalDB);
  Synchronize(WriteToForm);
end;

procedure TMyTimerThread.DoWork;
var s1,s4,ss1,ss2,ss3,ss4,ss5,bs1,bs2,bs3,bs4,bs5:string;
   snmp : tsnmpsend;
   fl: boolean;
begin
 fl := true;
 snmp := tsnmpsend.Create;
 try
   snmp.Query.Clear;
   snmp.Query.Community:='ubnt_mlink54';
   snmp.TargetHost := f_host;
   snmp.Query.PDUType := PDUGetRequest;
   s1:='1.3.6.1.4.1.14988.1.1.1.1.1.4.5';
   s4:='1.3.6.1.4.1.14988.1.1.1.1.1.6.5';
//   bs1 := '00:27:22:66:6A:C8';
   bs1 := '00:27:22:8C:4F:3D';
   bs2 := '00:27:22:8C:50:8B';
   bs3 := '00:15:6D:5E:AD:F0';
   bs4 := '00:27:22:8C:4F:2C';
//   bs5 := '00:27:22:8C:50:54';
   bs5 := 'DC:9F:DB:0C:B6:4C';
   ss1 := '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.79.61.5';
   ss2 := '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.80.139.5';
   ss3 := '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.21.109.94.173.240.5';
   ss4 := '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.79.44.5';
 //ss5 := '1.3.6.1.4.1.14988.1.1.1.2.1.3.0.39.34.140.80.84.5';
   ss5 := '1.3.6.1.4.1.14988.1.1.1.2.1.3.220.159.219.12.182.76.5';
   snmp.Query.MIBAdd(s1,'',ASN1_NULL);
   snmp.Query.MIBAdd(s4,'',ASN1_NULL);
   snmp.Query.MIBAdd(ss1,'',ASN1_NULL);
   snmp.Query.MIBAdd(ss2,'',ASN1_NULL);
   snmp.Query.MIBAdd(ss3,'',ASN1_NULL);
   snmp.Query.MIBAdd(ss4,'',ASN1_NULL);
   snmp.Query.MIBAdd(ss5,'',ASN1_NULL);
   F_DateTime := FormatDateTime('yyyy-mm-dd hh:nn:ss',now);
   F_Date := FormatDateTime('dd.mm.yyyy',now);//   F_Date := FormatDateTime('yyyy-mm-dd',now);
   F_Day := FormatDateTime('d',now);
   F_Month := FormatDateTime('m',now);
   F_year := FormatDateTime('yyyy',now);
   F_Time := FormatDateTime('hh:nn:ss',now);
   if snmp.SendRequest then
     begin
       F_level:=snmp.Reply.MIBGet(s1);
       F_AP :=convert_s(snmp.Reply.MIBGet(s4));
       if F_level ='' then
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
                 if F_level='' then fl := false;
               end;
             end;
           end;
         end;
       end;
       f_online :='1';
     end
     else
     begin
       F_level:='-100';
       F_AP :='00:00:00:00:00:00';
       f_online := '0';
     end;
    if fl then AddToBDB;
 except
   snmp.Free;
 end;
 snmp.Free;
end;


procedure TMyTimerThread.DoWork_AP;
var
 S1: string;
 snmp : tsnmpsend;

begin
  f_online := '1';
  F_DateTime := FormatDateTime('yyyy-mm-dd hh:nn:ss',now);
  F_Date := FormatDateTime('dd.mm.yyyy',now);//   F_Date := FormatDateTime('yyyy-mm-dd',now);
  F_Day := FormatDateTime('d',now);
  F_Month := FormatDateTime('m',now);
  F_year := FormatDateTime('yyyy',now);
  F_Time := FormatDateTime('hh:nn:ss',now);

     snmp := tsnmpsend.Create;
     try
       snmp.Query.Clear;
       snmp.Query.Community:='inspector';
       snmp.TargetHost := f_host;
       snmp.Query.PDUType := PDUGetRequest;
       s1:='1.2.840.10036.1.1.1.1.5';
       snmp.Query.MIBAdd(s1,'',ASN1_NULL);
       if snmp.SendRequest then
         begin
           F_AP:=snmp.Reply.MIBGet(s1);
           F_AP := Trim(F_AP);
           F_level := IntToStr(-1*(65+random(7)));
         end
         else begin
           F_level:='-100';
           F_AP :='00:00:00:00:00:00';
           f_online := '0';
         end;

     finally
       snmp.Free;
     end;

// Synchronize(GetSignalSSH);
 AddToBDB;
end;

procedure TMyTimerThread.Execute;
begin
  { Place thread code here }
  FreeOnTerminate := True;
  repeat
    if f_is_access_point then DoWork_AP
    else DoWork;
    Sleep(10000);
  until Terminated;
end;

Function FindEnter(AStr:string): integer;
var i: integer;
begin
  Result:=0;
  i := 0;
  while (AStr[i]<>#13)and(i<=Length(AStr)) do begin inc(Result);inc(i) end;
end;

(* procedure TMyTimerThread.GetSignalSSH;
var
  tmpStr1: string;
  j: byte;
begin
//
 tmpStr1 := Form1.GetSSHstring(f_host, 'admin', 'unrfce20', 'cat /proc/sys/dev/rssi-leds/signal');
 j:=FindEnter(tmpStr1);
 Delete(tmpStr1, 1, j+1);
 j:=FindEnter(tmpStr1);
 Delete(tmpStr1, j, Length(tmpStr1)-j);
 F_level := IntToStr(-1*StrtoInt(trim(tmpStr1)));
end;    *)

procedure TMyTimerThread.SaveToLocalDB;
begin
  with form1 do
     try
         if not statss_local.Active then statss_local.Active := true;
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

