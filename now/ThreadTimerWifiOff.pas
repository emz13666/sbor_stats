unit ThreadTimerWifiOff;

interface
uses Windows, Classes, forms, SSH_wifi, MyUtils, ADODB, ActiveX;

type
  TThreadTimerWifiOff = class(TThread)
  private
    { Private declarations }
    AQuery: TADOQuery;
    AConn: TADOConnection;
  protected
    procedure DoWork;
    procedure localdb_close_open;
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
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



constructor TThreadTimerWifiOff.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  CoInitialize(nil);
  AConn := TADOConnection.Create(nil);
  AConn.ConnectionString := 'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql_ubiquiti';
  AConn.Provider := 'MSDASQL.1';
  AConn.LoginPrompt := false;
  aconn.KeepConnection := false;
  AConn.Close;

  AQuery := TADOQuery.Create(nil);
  AQuery.Connection := AConn;
//  AQuery.ExecuteOptions := [eoAsyncExecute];
  AQuery.Close;

end;

destructor TThreadTimerWifiOff.Destroy;
begin
   AQuery.Close;
   AQuery.Connection := nil;
   FreeAndNil(AQuery);
   AConn.Close;
   FreeAndNil(AConn);
   CoUninitialize;
  inherited;
end;

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
  if Terminated then Exit;
 //Synchronize(localdb_close_open);

 datetime_proverka := now;
  try
    with AQuery do begin
      Close;
      SQL.Clear;
      SQL.Text := 'SELECT * FROM wifi_log ORDER BY id DESC LIMIT 1';
      Open;
      datetime_proverka := FieldByName('datetime').AsDateTime;
      Close;
    end;
    AConn.Close;
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
         AQuery.SQL.Text := 'insert into wifi_log(datetime, action) values('+
               QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', now))+',''OFA'')';
         AQuery.ExecSQL;
         AQuery.Close;
      end else FreeAndNil(sshconn1);
    end else  FreeAndNil(sshconn1);
 finally
   AQuery.Close;
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
     // Отключил - глючит. Да и не нужно пока что.
      //DoWork;
      begin_tick :=GetTickCount;
    end;
  until Terminated;
end;

procedure TThreadTimerWifiOff.localdb_close_open;
begin
  if Terminated then Exit;
  GlobCritSect.Enter;
  with form1 do
  try
    if statss_local.RecordCount>5000 then statss_local.SaveToFile;
    statss_local.Close;
    statss_local.Open;
    Memo1.Lines.Add('ok open-close statss_local');
    GlobCritSect.Leave;
  except
   on E:Exception do
   begin
    SaveLogToFile(LogFileName,'Ошибка при выполнении statss_local.SaveToFile в потоке ThreadTimerWifiOff'+' ('+E.ClassName+': '+E.Message+')');
    //LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении statss_local.SaveToFile в потоке ThreadTimerWifiOff');
    //LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
    GlobCritSect.Leave;
   end;
  end;

end;

end.

