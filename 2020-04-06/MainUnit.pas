unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI, DBXpress, Provider, SqlExpr, DB, DBClient,
  Grids, DBGrids, TTDBGrid, FMTBcd, ExtCtrls, RXShell, MyTimer,  syncobjs,
  ADODB, SyncThread, MoveToStatss_oldThread, Menus, ThreadTimerWifiOff, Spin,
  rxPlacemnt, MyUtils;// DelphiCryptlib, cryptlib;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Query: TADOQuery;
    ADOConnection1: TADOConnection;
    Label1: TLabel;
    Label2: TLabel;
    Button33: TButton;
    Query1: TADOQuery;
    Label3: TLabel;
    Label4: TLabel;
    Modems: TADOQuery;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    ADOConnection2: TADOConnection;
    Button2: TButton;
    QueryWifi_log: TADOQuery;
    ConnectionWifi_log: TADOConnection;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    RxTrayIcon1: TTrayIcon;
    Label5: TLabel;
    stats_ap_local: TClientDataSet;
    stats_ap_localid: TAutoIncField;
    stats_ap_localid_modem: TIntegerField;
    stats_ap_localsignal_level: TSmallintField;
    stats_ap_localdate: TDateField;
    stats_ap_localtime: TTimeField;
    stats_ap_localloadavg: TStringField;
    stats_ap_localmemfree: TStringField;
    stats_ap_localrx_octets_eth0: TStringField;
    stats_ap_localtx_octets_eth0: TStringField;
    chkPredvPing: TCheckBox;
    edtSnmpTimeout: TSpinEdit;
    Label6: TLabel;
    Label7: TLabel;
    edtPingUnreachble: TSpinEdit;
    Label8: TLabel;
    edtPeriodOprosa: TSpinEdit;
    statss_local: TClientDataSet;
    statss_localid: TAutoIncField;
    statss_localid_modem: TIntegerField;
    statss_localmac_ap: TStringField;
    statss_localsignal_level: TSmallintField;
    statss_localdate: TDateField;
    statss_localtime: TTimeField;
    statss_localstatus: TSmallintField;
    statss_localx: TIntegerField;
    statss_localy: TIntegerField;
    Modemsid_modem: TLargeintField;
    Modemsis_access_point: TSmallintField;
    Modemsis_ap_repeater: TWordField;
    Modemsmac_wds_peer: TStringField;
    Modemsfirmware: TStringField;
    Modemsname: TStringField;
    Modemsip_address: TStringField;
    Modemsequipment_type: TIntegerField;
    ModemsuseInMonitoring: TSmallintField;
    chkFirmwareVer: TCheckBox;
    FormStorage1: TFormStorage;
    chCollectStatsBullet: TCheckBox;
    chkSmotr2: TCheckBox;
    ADOConnection3: TADOConnection;
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Hide_appl(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button33Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Memo1Change(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure RxTrayIcon1Click(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    Procedure InitThreads;
    Procedure DestroyThreads;
  public
    { Public declarations }
  end;



var
  Form1: TForm1;
  GlobCritSect: TCriticalSection;
  MyThreadTimerWifiOff: TThreadTimerWifiOff;
  MyTimerThread: Array of TMyTimerThread;
  MySyncThread: TMySyncThread;
  VarMoveToStatssOld: TMoveToStatss_oldThreadThread;
//  LogError: TStrings;
  LogFileName: String;
//  ArrayIdModems5MinNoPing: Array of Byte;
  fl_threadsDestroyed: boolean;
implementation

{$R *.dfm}

procedure TForm1.RxTrayIcon1DblClick(Sender: TObject);
begin
  RxTrayIcon1.Visible := false;
  ShowWindow(Application.Handle,SW_SHOW);
  ShowWindow(Handle,SW_SHOW);
  Application.Restore;
  Application.BringToFront;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;
  LogFileName := ExtractFilePath(Application.ExeName)+'Log_err.txt';
  GlobCritSect := TCriticalSection.Create;
  FormStorage1.IniFileName := ExtractFilePath(Application.ExeName)+'sbor_stats.ini';
  FormStorage1.RestoreFormPlacement;
  statss_local.FileName := ExtractFilePath(Application.ExeName)+'statss_local.cds';
  statss_local.Open;
  statss_local.LogChanges := false;

  stats_ap_local.FileName :=ExtractFilePath(Application.ExeName)+'statss_ap_local.cds';
  stats_ap_local.Open;
  stats_ap_local.LogChanges := false;
  Label4.Caption := IntToStr(statss_local.RecordCount);
  Label5.Caption := IntToStr(stats_ap_local.RecordCount);
  RxTrayIcon1.Visible := true;
  Application.OnMinimize := Hide_appl;

  fl_threadsDestroyed := true;
  InitThreads;

  chkFirmwareVer.Enabled := false;
  chkPredvPing.Enabled := false;
  chCollectStatsBullet.Enabled := false;
  edtSnmpTimeout.Enabled := false;
  edtPingUnreachble.Enabled := false;
  edtPeriodOprosa.Enabled := false;
end;

procedure TForm1.Hide_appl(Sender: TObject);
begin
  RxTrayIcon1.Visible := true;
  Application.Minimize;
  //Application.ShowMainForm := false;
  ShowWindow(Application.Handle,SW_HIDE);
//  ShowWindow(Application.MainForm.Handle,SW_HIDE);
end;


procedure TForm1.InitThreads;
var
 maxIdModem,i: Integer;
begin
  if not fl_threadsDestroyed then exit;

  Modems.Close;
  try
    Modems.SQL.Text := 'SELECT m.id_modem, m.is_access_point, m.is_ap_repeater, m.mac_wds_peer, m.firmware, e.name, e.ip_address, e.equipment_type,'+
     ' e.useInMonitoring  FROM modems m, equipment e WHERE e.useInMonitoring=1 and '+
     'e.ip_address=m.ip_address  order by e.name';
    Modems.Open;
    SaveLogToFile(LogFileName,'InitThreads begin...');
    maxIdModem := 0;
    while not Modems.Eof do
    begin
      if maxIdModem < Modemsid_modem.AsInteger then maxIdModem := Modemsid_modem.AsInteger;
      Modems.Next;
    end;
//    SetLength(ArrayIdModems5MinNoPing, maxIdModem+1);

  //  for i := 1 to maxIdModem do ArrayIdModems5MinNoPing[i]:=0;

    Modems.First;
    SetLength(myTimerThread,0);
    while not Modems.Eof do
    begin
      if maxIdModem < Modemsid_modem.AsInteger then maxIdModem := Modemsid_modem.AsInteger;
      SetLength(myTimerThread,Length(MyTimerThread)+1);
      MyTimerThread[high(MyTimerThread)] := TMyTimerThread.Create(true,Modemsip_address.AsString,edtSnmpTimeout.Value);
      MyTimerThread[high(MyTimerThread)].F_IDModem := Modemsid_modem.AsString;
      MyTimerThread[high(MyTimerThread)].f_nameModem := Modems.FieldByName('name').AsString;
      if (Modemsequipment_type.AsInteger=3) then MyTimerThread[high(MyTimerThread)].status_default := 2
        else MyTimerThread[high(MyTimerThread)].status_default := 0;
      if (Modemsfirmware.AsString='5.5') then
        MyTimerThread[high(MyTimerThread)].f_new := false
      else MyTimerThread[high(MyTimerThread)].f_new := true;
      MyTimerThread[high(MyTimerThread)].f_is_access_point := (Modemsis_access_point.AsInteger=1);
      MyTimerThread[high(MyTimerThread)].f_is_ap_repeater := (Modems.FieldByName('is_ap_repeater').AsInteger=1);
      MyTimerThread[high(MyTimerThread)].F_mac_wds_peer := Modems.FieldByName('mac_wds_peer').AsString;
      MyTimerThread[high(MyTimerThread)].PredvPing := chkPredvPing.Checked;
      MyTimerThread[high(MyTimerThread)].f_chk_ver := chkFirmwareVer.Checked;
      MyTimerThread[high(MyTimerThread)].f_is_collect_net_stat := chCollectStatsBullet.Checked;
      MyTimerThread[high(MyTimerThread)].PeriodOprosa := edtPeriodOprosa.Value;
      MyTimerThread[high(MyTimerThread)].PeriodUnreachble := edtPingUnreachble.Value;
      MyTimerThread[high(MyTimerThread)].FreeOnTerminate := true;
      MyTimerThread[high(MyTimerThread)].Start;
      sleep(8);
      Application.ProcessMessages;
      Sleep(random(80));
      Application.ProcessMessages;
      Modems.Next;
    end;
    modems.Close;
  except
    on E:Exception do
    begin
    GlobCritSect.Enter;
    SaveLogToFile(LogFileName, '���������� ���������������� ������ - ��� ������� � ����'+' ('+E.ClassName+': '+E.Message+')');
    GlobCritSect.Leave;
    Application.Terminate;
    end;
  end;
  MySyncThread := TMySyncThread.Create(true);
  MySyncThread.FreeOnTerminate := true;
  MySyncThread.Start;
  //MyThreadTimerWifiOff := TThreadTimerWifiOff.Create(true);
  //MyThreadTimerWifiOff.FreeOnTerminate := true;
  VarMoveToStatssOld := TMoveToStatss_oldThreadThread.Create(true);
  VarMoveToStatssOld.FreeOnTerminate := true;
  VarMoveToStatssOld.Start;
  //LogError := Memo1.Lines;
  //LogError.Clear;
  //if FileExists(ExtractFilePath(Application.ExeName)+'LogError.txt') then
   // LogError.LoadFromFile(ExtractFilePath(Application.ExeName)+'LogError.txt')
  //else
    //LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
   if FileExists(LogFileName) then Memo1.Lines.LoadFromFile(LogFileName);
  sleep(100);
{  if chkSmotr2.Checked then
    MyThreadTimerWifiOff.Start;}
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'InitThreads done.');
  GlobCritSect.Leave;
  fl_threadsDestroyed := False;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  Hide_appl(@Self);
end;

procedure TForm1.FormDestroy(Sender: TObject);
var i: Integer;
begin
  try
//  statss_local.SaveToFile;
  statss_local.Close;
  stats_ap_local.Close;
  FreeAndNil(GlobCritSect);
  except
    on E:Exception do SaveLogToFile(LogFileName,'Error in destroying threads. ('+E.ClassName+': '+E.Message+')');
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Memo1.Perform(EM_LINESCROLL,0,Memo1.Lines.Count-1);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 (* LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogErrorOld'+
      FormatDateTime('yyyymmdd-hhnnss',now)+'.txt');
  LogError.Clear;
  LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  Label2.Caption := '000';*)
end;

procedure TForm1.Button33Click(Sender: TObject);
begin
  if not statss_local.Active then statss_local.Open;
  if not stats_ap_local.Active then stats_ap_local.Open;

  statss_local.EmptyDataSet;
  stats_ap_local.EmptyDataSet;
  Label4.Caption := IntToStr(statss_local.RecordCount);
  Label5.Caption := IntToStr(stats_ap_local.RecordCount);
  statss_local.SaveToFile();
  stats_ap_local.SaveToFile();
  statss_local.Close;
  stats_ap_local.Close;
//  statss_local.LoadFromFile;
end;

procedure TForm1.N5Click(Sender: TObject);
begin
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Exiting...');
  GlobCritSect.Leave;
  Close;
end;

procedure TForm1.Button2Click(Sender: TObject);
var i: integer;
begin

  Button2.Enabled := false;
  Cursor := crHourGlass;
  Application.ProcessMessages;

  DestroyThreads;

  Button3.Enabled := true;
  Cursor := crDefault;
    chkFirmwareVer.Enabled := true;
  chkPredvPing.Enabled := true;
  chCollectStatsBullet.Enabled := true;
  edtSnmpTimeout.Enabled := true;
  edtPingUnreachble.Enabled := true;
  edtPeriodOprosa.Enabled := true;

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if MessageDlg('Exit now?',  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
 begin
   DestroyThreads;
   GlobCritSect.Enter;
   SaveLogToFile(LogFileName, 'Exiting...');
   GlobCritSect.Leave;
   Action := caFree;
 end
 else
  Action := caNone;
end;

procedure TForm1.Memo1Change(Sender: TObject);
begin
//  Label2.Caption := IntToStr(LogError.Count);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Button3.Enabled := false;
  Cursor := crHourGlass;

  InitThreads;

  Button2.Enabled := true;
  Cursor := crDefault;
  chkFirmwareVer.Enabled := false;
  chkPredvPing.Enabled := false;
  chCollectStatsBullet.Enabled := false;
  edtSnmpTimeout.Enabled := false;
  edtPingUnreachble.Enabled := false;
  edtPeriodOprosa.Enabled := false;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
{  if MyThreadTimerWifiOff.Suspended then begin
    MyThreadTimerWifiOff.Resume;
    Button4.Caption := 'Stop_checkWIFI';
    chkSmotr2.Checked := true;
  end
  else begin
    Button4.Caption := 'Start_checkWIFI';
    MyThreadTimerWifiOff.Suspend;
    chkSmotr2.Checked := false;
  end;}
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  statss_local.Close;
  stats_ap_local.Close;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  if VarMoveToStatssOld.Suspended then begin
    VarMoveToStatssOld.Resume;
    Button6.Caption := 'Stop MoveToStatss_oldThread';
  end
  else begin
    Button6.Caption := 'Start MoveToStatss_oldThread';
    VarMoveToStatssOld.Suspend;
  end;
end;

procedure TForm1.DestroyThreads;
var
  i: word;
begin

 if  fl_threadsDestroyed then exit;
try
 if Length(MyTimerThread)>0 then
  begin
   GlobCritSect.Enter;
   SaveLogToFile(LogFileName,'Destroing modem''s threads begin');
   GlobCritSect.Leave;
   for i := 0 to High(MyTimerThread) do
    if Assigned(MyTimerThread[i]) then begin
//      if MyTimerThread[i].Suspended then MyTimerThread[i].Resume;
      MyTimerThread[i].Terminate;
//      MyTimerThread[i].WaitFor;
//      MyTimerThread[i].Free;
    end;
     SetLength(MyTimerThread,0);
   GlobCritSect.Enter;
   SaveLogToFile(LogFileName,'Destroing modem''s threads end');
   GlobCritSect.Leave;
  end;
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying SyncThread begin');
  GlobCritSect.Leave;
  if Assigned(MySyncThread) then begin
    //MySyncThread.Suspended then MySyncThread.Resume;
    MySyncThread.Terminate;
  end;
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying SyncThread end');
  SaveLogToFile(LogFileName,'Destroying MoveToStatssOldThread begin');
  GlobCritSect.Leave;
  if Assigned(VarMoveToStatssOld) then  begin
    //if VarMoveToStatssOld.Suspended then VarMoveToStatssOld.Resume;
    VarMoveToStatssOld.Terminate;
  end;
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying MoveToStatssOldThread end');
 // SaveLogToFile(LogFileName,'Destroying ThreadTimerWifiOff begin');
  GlobCritSect.Leave;
{  if Assigned(MyThreadTimerWifiOff) then  begin
    MyThreadTimerWifiOff.Terminate;
    if MyThreadTimerWifiOff.Suspended then MyThreadTimerWifiOff.Resume;
  end;
//  SetLength(ArrayIdModems5MinNoPing,0);
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying ThreadTimerWifiOff end');
  GlobCritSect.Leave;}
  fl_threadsDestroyed := true;
except
  on E:Exception do SaveLogToFile(LogFileName,'Error in destroying threads. ('+E.ClassName+': '+E.Message+')');
end;
end;

procedure TForm1.RxTrayIcon1Click(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  RxTrayIcon1.Visible := false;
  ShowWindow(Application.Handle,SW_SHOW);
  ShowWindow(Handle,SW_SHOW);
  Application.Restore;
  Application.BringToFront;
end;

end.


