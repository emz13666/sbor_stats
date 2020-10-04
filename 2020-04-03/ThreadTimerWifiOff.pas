unit ThreadTimerWifiOff;

interface
uses Windows, Classes, forms, SSH_wifi;

type
  TThreadTimerWifiOff = class(TThread)
  private
    { Private declarations }
  protected
    procedure DoWork;
    procedure localdb_close_open;
    procedure Execute; override;
  public

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



procedure TThreadTimerWifiOff.DoWork;
var
  datetime_proverka: TDateTime;

var
  SSHconn1: TSSHobj;
  i: byte;
  fl_on: byte;
  f_ip_ap, f_user_ap, f_passwd_ap:AnsiString;
  begin_tick: cardinal;
begin
 //Synchronize(localdb_close_open);
 datetime_proverka := now;
  try
  Form1.QueryWifi_log.Close;
  Form1.ConnectionWifi_log.Close;
  Form1.QueryWifi_log.SQL.Clear;
  Form1.QueryWifi_log.SQL.Text := 'SELECT * FROM wifi_log ORDER BY id DESC LIMIT 1';
  Form1.QueryWifi_log.Open;
  datetime_proverka := Form1.QueryWifi_log.FieldByName('datetime').AsDateTime;
  //Form1.Memo1.Lines.Add('datetime_proverka='+Form1.QueryWifi_log.FieldByName('datetime').AsString);
  Form1.QueryWifi_log.Close;
  Form1.ConnectionWifi_log.Close;
  //Form1.Memo1.Lines.Add('now='+FormatDateTime('dd.mm.yyyy hh:nn:ss',now));
  //Form1.Memo1.Lines.Add('now-datetime_proverka='+FloatToStrF(now-datetime_proverka,ffFixed,7,4));
  except
    //
  end;

  f_ip_ap := '10.70.120.22';
  f_user_ap := 'admin';
  f_passwd_ap := 'unrfce20';
  fl_on :=2; //unknown status

 //проверяем последнюю запись в таблице wifi_log
 //если wifi не отключен и now-datetime > 2,5 часа то отключает wifi если еще не отключен.
 //для отладки - 1 минута
 try
    SSHconn1 := TSSHobj.Create(f_ip_ap,f_user_ap,f_passwd_ap,'XM.v5.6.15-sign-cpu400.31612.170908.1458#');
    SSHconn1.FCommand := 'ifconfig ath0|grep MTU';
    if SSHconn1.Execute then
    begin
      //Form1.Memo1.Lines.Add('SSHConn.Answer="');
      //Form1.Memo1.Lines.Add(sshconn1.Answer.Text);
      //Form1.Memo1.Lines.Add('"');
      if (FindLineSubstringInList('UP',sshconn1.answer)>-1) and  (now-datetime_proverka>1/24*2.5{1/24/60}) then  begin
         SSHconn1.fcommand := 'grep -v "netconf.2.up=" /tmp/system.cfg > /tmp/tempconfig;echo "netconf.2.up=disabled" >> /tmp/tempconfig;mv /tmp/tempconfig /tmp/system.cfg;cfgmtd -w -p /etc/';
         SSHconn1.Execute;
         sleep(1000);
         SSHconn1.fcommand := 'reboot';
         SSHconn1.Execute;
         Form1.Memo1.Lines.Add(FormatDateTime('dd.mm.yyyy hh:nn:ss',now)+': WLAN0 Disabled on '+f_ip_ap);
         FreeAndNil(SSHconn1);

         begin_tick := gettickcount;
         while GetTickCount - begin_tick < 50500 do
           if not Terminated then sleep(10) else break;
         Form1.QueryWifi_log.SQL.Text := 'insert into wifi_log(datetime, action) values('+
               QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', now))+',''OFA'')';
         Form1.QueryWifi_log.ExecSQL;
         Form1.QueryWifi_log.Close;
      end else FreeAndNil(sshconn1);
    end else  FreeAndNil(sshconn1);
 finally
   Form1.QueryWifi_log.Close;
   FreeAndNil(sshconn1);
 end;
end;

procedure TThreadTimerWifiOff.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  if Terminated then  exit;
  if Suspended then exit;
  if form1.chkSmotr2.Checked then
    else exit;

  repeat
    //10 minutes
    //6 секунд для отладки
    while GetTickCount - begin_tick < 600000{6000} do
      if not Terminated then sleep(10) else break;
    if Suspended then continue;
    if not Terminated then
    begin
      DoWork;
      begin_tick :=GetTickCount;
    end;
  until Terminated;
end;

procedure TThreadTimerWifiOff.localdb_close_open;
begin
  GlobCritSect.Enter;
  with form1 do
  try
    if statss_local.RecordCount>5000 then statss_local.SaveToFile;
    statss_local.Close;
    statss_local.Open;
    Memo1.Lines.Add('ok open-close statss_local');
    GlobCritSect.Leave;
  except
    LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении statss_local.SaveToFile в потоке ThreadTimerWifiOff');
    LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
    GlobCritSect.Leave;
  end;

end;

end.

