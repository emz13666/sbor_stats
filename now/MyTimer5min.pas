unit MyTimer5min;

interface
uses Classes, forms, snmpsend, pingsend, asn1util, windows, ADODB,Messages, MyUtils;

type
  TMyTimer5minThread = class(TThread)
  private
    { Private declarations }
    snmp : TSNMPSend;
    AQuery: TADOQuery;
    AConn: TADOConnection;
    function ReadFirmwareVer(fHost: AnsiString):AnsiString;
  protected
    procedure SaveFirmwareToMySQL(F_IDModem, f_firmware: AnsiString);
    procedure Do_Work;
    procedure UpdateMemoOnForm;
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

    procedure TMyTimer5minThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TMyTimer5minThread }

function GetBulletFWVersion(AValue:AnsiString):Ansistring;
var fstr: AnsiString;
begin
  if AValue='' then Result:='';
  fstr := Copy(AValue,pos('v',AValue)+1,Length(AValue)-pos('v',AValue));
  Result := Copy (fstr,1,pos('.',fstr)-1);
  fstr := Copy (fstr,pos('.',fstr)+1,length(fstr)-pos('.',fstr));
  Result := Result + '.' + Copy (fstr,1,pos('.',fstr)-1);
end;

constructor TMyTimer5minThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  AQuery := TADOQuery.Create(Application);
  AConn := TADOConnection.Create(Application);
  AConn.ConnectionString := 'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql_ubiquiti';
  AConn.Provider := 'MSDASQL.1';
  AConn.LoginPrompt := false;
  AQuery.Connection := AConn;
  AConn.Close;
  snmp := tsnmpsend.Create;
end;

destructor TMyTimer5minThread.Destroy;
begin
   AQuery.Close;AQuery.Connection := nil;
   FreeAndNil(AQuery);
   AConn.Close; FreeAndNil(AQuery);
   FreeAndNil(snmp);
  inherited;
end;

procedure TMyTimer5minThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  repeat
     // 1 раз в 5 минут проверяем на устройстве версию прошивки и обновляем её в базе при необходимости
     //1 раз в 5 минут считываем из базы параметр is_ap_repeater

     //sleep 5 мин
     begin_tick := GetTickCount;
     while ((GetTickCount - begin_tick) < 5*60*1000) do
       if not Terminated then sleep(10) else break;
     Do_Work;
  until Terminated;
end;

function TMyTimer5minThread.ReadFirmwareVer(fHost: AnsiString): AnsiString;
var s2,s3:AnsiString;
begin
  if Terminated then Exit;
     try
       Result := '';
       snmp.Query.Clear;
       snmp.Query.Community:='ubnt_mlink54';
       snmp.TargetHost := fHost;
       snmp.Query.PDUType := PDUGetRequest;
       s2:='1.2.840.10036.3.1.2.1.4.5'; //firmware
       snmp.Query.MIBAdd(s2,'',ASN1_NULL);
       if snmp.SendRequest then
         begin
           s3:=snmp.Reply.MIBGet(s2);
           Result:=GetBulletFWVersion(s3);
         end;
     except
      on E:Exception do
      begin
       GlobCritSect.Enter;
       SaveLogToFile(LogFileName,'Ошибка в ReadFirmwareVer. fHost: '+fHost+' ('+E.ClassName+': '+E.Message+')');
       GlobCritSect.Leave;
      end;
     end;
end;

procedure TMyTimer5minThread.Do_Work;
var
  i: integer; f_firmware: AnsiString;
  f_is_ap_rep_old: boolean;
begin
  if Terminated then Exit;
 try
  try
    for i := 0 to high(MyTimerThread) do
    begin
      if Terminated then Break;
      if (not Terminated) and Assigned(MyTimerThread[i]) then
      begin
        if MyTimerThread[i].f_is_lte then Continue;
        if MyTimerThread[i].f_is_work_of_ping then Continue;
        AQuery.Close;
        AQuery.SQL.Text := 'select * from modems where id_equipment='+MyTimerThread[i].f_idEquipment;
        AQuery.Open;
          f_is_ap_rep_old := MyTimerThread[i].f_is_ap_repeater;
          MyTimerThread[i].f_is_ap_repeater := (AQuery.FieldByName('is_ap_repeater').AsInteger=1);
          if MyTimerThread[i].f_is_ap_repeater xor f_is_ap_rep_old then begin
            if MyTimerThread[i].f_is_ap_repeater then begin
                MyTimerThread[i].F_mac_wds_peer := AQuery.FieldByName('mac_wds_peer').AsString;
                SaveLogToFile(LogFileName,'Поле F_mac_wds_peer для '+ MyTimerThread[i].f_nameModem +
              ' установлено в '+ MyTimerThread[i].F_mac_wds_peer);
            end;
            SaveLogToFile(LogFileName,'Флаг f_is_ap_repeater для '+ MyTimerThread[i].f_nameModem +
              ' установлен в '+ BooleanToString(MyTimerThread[i].f_is_ap_repeater));
            Synchronize(UpdateMemoOnForm);
          end;

          f_firmware := ReadFirmwareVer(MyTimerThread[i].f_host);
          if f_firmware<>'' then MyTimerThread[i].f_new := (f_firmware <> '5.5');
          AQuery.Close;
          if f_firmware<>MyTimerThread[i].f_firmware_thread then
          begin
             SaveFirmwareToMySQL(MyTimerThread[i].f_idEquipment,f_firmware);
             if f_firmware <>'' then begin
               SaveLogToFile(LogFileName,'Информация о firmware для ' + MyTimerThread[i].f_nameModem+
                  ' обновлена с '+ MyTimerThread[i].f_firmware_thread + ' до '+f_firmware);
               Synchronize(UpdateMemoOnForm);
               MyTimerThread[i].f_firmware_thread:= f_firmware;
             end;
          end;
      end;
    end;
  except
   on E:Exception do
   begin
     GlobCritSect.Enter;
     SaveLogToFile(LogFileName,'Ошибка в потоке проверки firmware и is_ap_repeater. ('+E.ClassName+': '+E.Message+')');
     Synchronize(UpdateMemoOnForm);
     GlobCritSect.Leave;
   end;
  end;
 finally
      AQuery.Close;
      AConn.Close;
 end;
end;


procedure TMyTimer5minThread.SaveFirmwareToMySQL(F_IDModem, f_firmware: AnsiString);
begin
  if Terminated then Exit;
 if f_firmware='' then exit;

 try
  try
      AQuery.Close;
      AQuery.SQL.Text := 'Update modems set firmware=' + QuotedStr(f_firmware)+' where id_equipment='+F_IDModem;
      AQuery.ExecSQL;
  except
    on E:Exception do
    begin
     GlobCritSect.Enter;
     SaveLogToFile(LogFileName,'Ошибка в SaveFirmwareToMySQL. Equipment:'+F_IDModem+' ('+E.ClassName+': '+E.Message+')');
     Synchronize(UpdateMemoOnForm);
     GlobCritSect.Leave;
    end;
  end;
 finally
      AQuery.Close;
      AConn.Close;
 end;
end;

procedure TMyTimer5minThread.UpdateMemoOnForm;
begin
  if Terminated then Exit;
  Form1.Memo1.Lines.LoadFromFile(LogFileName);
  Form1.Memo1.Perform(EM_LINESCROLL,0,Form1.Memo1.Lines.Count-1);
end;

end.

