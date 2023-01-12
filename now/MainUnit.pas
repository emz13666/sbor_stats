unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI, DBXpress, Provider, SqlExpr, DB, DBClient,
  Grids, DBGrids, TTDBGrid, FMTBcd, ExtCtrls, RXShell, MyTimer, MyTimer5min,  syncobjs,
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
    Label3: TLabel;
    Label4: TLabel;
    Modems: TADOQuery;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    btnStopSbor: TButton;
    btnStartSbor: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
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
    FormStorage1: TFormStorage;
    chCollectStatsBullet: TCheckBox;
    chkSmotr2: TCheckBox;
    stats_lte: TClientDataSet;
    stats_lteid: TAutoIncField;
    stats_lteid_equipment: TLargeintField;
    stats_ltedate: TDateField;
    stats_ltetime: TTimeField;
    stats_ltedatetime: TDateTimeField;
    stats_ltesignal_rsrp: TIntegerField;
    stats_ltesignal_rsrq: TIntegerField;
    stats_ltesignal_sinr: TIntegerField;
    Label9: TLabel;
    stats_ping: TClientDataSet;
    stats_pingid: TAutoIncField;
    stats_pingid_equipment: TLargeintField;
    stats_pingDate: TDateField;
    stats_pingTime: TTimeField;
    stats_pingDatetime: TDateTimeField;
    stats_pingtime_ping: TIntegerField;
    stats_ap_localid_equipment: TLargeintField;
    statss_localid_equipment: TLargeintField;
    lblCountPing: TLabel;
    lblCountThreads: TLabel;
    RxTrayIcon: TRxTrayIcon;
    TimerCheckRestartSbor: TTimer;
    QueryCheckRestartSbor: TADOQuery;
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Hide_appl(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button33Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure btnStopSborClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Memo1Change(Sender: TObject);
    procedure btnStartSborClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure RxTrayIcon1Click(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure TimerCheckRestartSborTimer(Sender: TObject);
  private
    { Private declarations }
    Procedure InitThreads;
    Procedure DestroyThreads;
  public
    { Public declarations }
  end;

const
  free_on_term = false;
  flag_debug = false;

var
  Form1: TForm1;
  CountThreads: word;
  GlobCritSect: TCriticalSection;
  MyThreadTimerWifiOff: TThreadTimerWifiOff;
  My_timer_5min: TMyTimer5minThread;
  MyTimerThread: Array of TMyTimerThread;
  MySyncThread: TMySyncThread;
  VarMoveToStatssOld: TMoveToStatss_oldThreadThread;
//  LogError: TStrings;
  LogFileName: String;
//  ArrayIdModems5MinNoPing: Array of Byte;
  fl_threadsDestroyed: boolean;
  FormCreated: boolean = false;
//  arrStats: array [0..3] of AnsiString = ('statss', 'stats_ap', 'stats_lte', 'stats_ping');

implementation

{$R *.dfm}

procedure TForm1.RxTrayIcon1DblClick(Sender: TObject);
begin
  RxTrayIcon.Active := false;
  ShowWindow(Application.Handle,SW_SHOW);
  ShowWindow(Handle,SW_SHOW);
  Application.Restore;
  Application.BringToFront;
end;

procedure TForm1.TimerCheckRestartSborTimer(Sender: TObject);
begin
// ��� � 2 ������ ��������� ���������� � �� - � ���� ��� =1 �� - ������� ���� ���������� � ��������� ���������� � 0
  TimerCheckRestartSbor.Enabled := false;
  with QueryCheckRestartSbor do
  begin
    Close;
    SQL.Text := 'Select name, value from variables where name="restart_sbor"';
    Open;
    if (RecordCount=1) then
      if  (FieldByName('value').AsInteger=1) then
      begin
        if btnStopSbor.Enabled then btnStopSborClick(Sender);
        sleep(1000);
        if btnStartSbor.Enabled then btnStartSborClick(Sender);
        Close;
        Sql.Text := 'Update variables set value=0 where name="restart_sbor"';
        ExecSQL;
      end;
    Close;
  end;
  TimerCheckRestartSbor.Enabled := true;
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

  stats_lte.FileName := ExtractFilePath(Application.ExeName)+'stats_lte.cds';
  stats_lte.Open;
  stats_lte.LogChanges := false;

  stats_ping.FileName := ExtractFilePath(Application.ExeName)+'stats_ping.cds';
  stats_ping.Open;
  stats_ping.LogChanges := false;

  Label4.Caption := IntToStr(statss_local.RecordCount);
  Label5.Caption := IntToStr(stats_ap_local.RecordCount);
  Label9.Caption := IntToStr(stats_lte.RecordCount);
  RxTrayIcon.active := true;
  Application.OnMinimize := Hide_appl;

  fl_threadsDestroyed := true;
  InitThreads;

  chkPredvPing.Enabled := false;
  chCollectStatsBullet.Enabled := false;
  edtSnmpTimeout.Enabled := false;
  edtPingUnreachble.Enabled := false;
  edtPeriodOprosa.Enabled := false;
  FormCreated := true;
  TimerCheckRestartSbor.Enabled := true;
end;

procedure TForm1.Hide_appl(Sender: TObject);
begin
  RxTrayIcon.Active := true;
  Application.Minimize;
  //Application.ShowMainForm := false;
  ShowWindow(Application.Handle,SW_HIDE);
//  ShowWindow(Application.MainForm.Handle,SW_HIDE);
end;


procedure TForm1.InitThreads;
var
 i: Integer;
begin
  if not fl_threadsDestroyed then exit;

  Modems.Close;
  try
    Modems.SQL.Text := 'SELECT m.id_modem, m.is_access_point, m.is_ap_repeater, m.mac_wds_peer, m.firmware, e.name, e.ip_address, e.ip_pc, e.ip_alias, e.equipment_type,'+
     ' e.useInMonitoring, e.id  FROM modems m, equipment e WHERE e.useInMonitoring=1 and '+
     'e.id=m.id_equipment order by e.name'; //for debug: and e.name = "EX19"
    Modems.Open;
    SaveLogToFile(LogFileName,'InitThreads begin...');
    Modems.First;
    SetLength(myTimerThread,0);
    CountThreads := 0;

       VarMoveToStatssOld := TMoveToStatss_oldThreadThread.Create(true);
       VarMoveToStatssOld.FreeOnTerminate := free_on_term;
       VarMoveToStatssOld.Start;
       Inc(CountThreads);


    while not Modems.Eof do
    begin
      SetLength(myTimerThread,Length(MyTimerThread)+1);
      MyTimerThread[high(MyTimerThread)] := TMyTimerThread.Create(true,Modems.FieldByName('ip_address').AsString,edtSnmpTimeout.Value);
      Inc(CountThreads);
      MyTimerThread[high(MyTimerThread)].F_IDModem := Modems.FieldByName('id_modem').AsString;
      MyTimerThread[high(MyTimerThread)].f_idEquipment := Modems.FieldByName('id').AsString;
      MyTimerThread[high(MyTimerThread)].f_eq_type := Modems.FieldByName('equipment_type').AsInteger;
      if copy(Modems.FieldByName('name').AsString,1,3)='SZM' then
      begin
        MyTimerThread[high(MyTimerThread)].f_host_alias := Modems.FieldByName('ip_alias').AsString;
        MyTimerThread[high(MyTimerThread)].f_is_alias := true;
      end
      else
        MyTimerThread[high(MyTimerThread)].f_is_alias := false;
      MyTimerThread[high(MyTimerThread)].f_nameModem := Modems.FieldByName('name').AsString;
      if (Modems.FieldByName('equipment_type').AsInteger=3) then MyTimerThread[high(MyTimerThread)].status_default := 2
        else MyTimerThread[high(MyTimerThread)].status_default := 0;
      MyTimerThread[high(MyTimerThread)].f_firmware_thread := Modems.FieldByName('firmware').AsString;
      MyTimerThread[high(MyTimerThread)].f_new := (Modems.FieldByName('firmware').AsString<>'5.5');
      MyTimerThread[high(MyTimerThread)].f_is_access_point := (Modems.FieldByName('is_access_point').AsInteger=1);
      MyTimerThread[high(MyTimerThread)].f_is_ap_repeater := (Modems.FieldByName('is_ap_repeater').AsInteger=1);
      MyTimerThread[high(MyTimerThread)].F_mac_wds_peer := Modems.FieldByName('mac_wds_peer').AsString;
      MyTimerThread[high(MyTimerThread)].PredvPing := chkPredvPing.Checked;
      MyTimerThread[high(MyTimerThread)].f_is_work_of_ping := false;
//      MyTimerThread[high(MyTimerThread)].f_chk_ver := chkFirmwareVer.Checked;
      MyTimerThread[high(MyTimerThread)].f_is_collect_net_stat := chCollectStatsBullet.Checked;
      MyTimerThread[high(MyTimerThread)].PeriodOprosa := edtPeriodOprosa.Value;
      MyTimerThread[high(MyTimerThread)].PeriodUnreachble := edtPingUnreachble.Value;
      MyTimerThread[high(MyTimerThread)].FreeOnTerminate := free_on_term;
      MyTimerThread[high(MyTimerThread)].Start;
//      sleep(8);

//2021-08-16: ������ ������ ��� ����� ping �� ���-�� � �����-��:
      SetLength(myTimerThread,Length(MyTimerThread)+1);
      if (Modems.FieldByName('equipment_type').AsInteger in [1,2,5,6]) then begin
          MyTimerThread[high(MyTimerThread)] := TMyTimerThread.Create(true,Modems.FieldByName('ip_pc').AsString,edtSnmpTimeout.Value);
          Inc(CountThreads);
          MyTimerThread[high(MyTimerThread)].f_idEquipment := Modems.FieldByName('id').AsString;
          MyTimerThread[high(MyTimerThread)].F_IDModem := Modems.FieldByName('id_modem').AsString;
          MyTimerThread[high(MyTimerThread)].f_eq_type := Modems.FieldByName('equipment_type').AsInteger;
          if Modems.FieldByName('equipment_type').AsInteger=6 {SZM} then
          begin
            //������� �����_�����(ip_alias+2)
            MyTimerThread[high(MyTimerThread)].f_host_alias := AddIPaddress(Modems.FieldByName('ip_alias').AsString,2);
            MyTimerThread[high(MyTimerThread)].f_is_alias := true;
          end
          else
            MyTimerThread[high(MyTimerThread)].f_is_alias := false;
          MyTimerThread[high(MyTimerThread)].f_nameModem := Modems.FieldByName('name').AsString;
          MyTimerThread[high(MyTimerThread)].status_default := 0;
          MyTimerThread[high(MyTimerThread)].f_new := false;
          MyTimerThread[high(MyTimerThread)].f_is_access_point := false;
          MyTimerThread[high(MyTimerThread)].f_is_ap_repeater := false;
          MyTimerThread[high(MyTimerThread)].f_is_work_of_ping := true;
          MyTimerThread[high(MyTimerThread)].f_is_collect_net_stat := false;
          MyTimerThread[high(MyTimerThread)].PeriodOprosa := edtPeriodOprosa.Value;
          MyTimerThread[high(MyTimerThread)].PeriodUnreachble := edtPingUnreachble.Value;
          MyTimerThread[high(MyTimerThread)].FreeOnTerminate := free_on_term;
          MyTimerThread[high(MyTimerThread)].Start;
  //        sleep(8);
      end;

      //Application.ProcessMessages;
    //  Sleep(random(80));
      //Application.ProcessMessages;
      Modems.Next;
    end;
    modems.Close;
    //��������� ������ ��� ����� ���������� ������� LTE
    Query.SQL.Text := 'SELECT l.id_equipment, e.name, l.ip_vpn, l.ip_lte, l.model_lte,'+
     ' e.useInMonitoring, e.equipment_type  FROM lte l, equipment e WHERE e.useInMonitoring=1 and '+
     'e.id=l.id_equipment order by e.name';  //for debug: and e.name = "EX19"
    Query.Open;
    Query.First;
    while not Query.Eof do
    begin
      SetLength(myTimerThread,Length(MyTimerThread)+1);
      MyTimerThread[high(MyTimerThread)] := TMyTimerThread.Create(true,Query.FieldByName('ip_lte').AsString,edtSnmpTimeout.Value);
      Inc(CountThreads);
      MyTimerThread[high(MyTimerThread)].f_idEquipment := Query.FieldByName('id_equipment').AsString;
      MyTimerThread[high(MyTimerThread)].f_eq_type := Query.FieldByName('equipment_type').AsInteger;
      MyTimerThread[high(MyTimerThread)].f_is_lte := true;
      MyTimerThread[high(MyTimerThread)].f_type_lte := Query.FieldByName('model_lte').AsString;
      MyTimerThread[high(MyTimerThread)].f_is_alias := false;
      MyTimerThread[high(MyTimerThread)].f_nameModem := Query.FieldByName('name').AsString;
      MyTimerThread[high(MyTimerThread)].f_new := false;
      MyTimerThread[high(MyTimerThread)].f_is_access_point := false;
      MyTimerThread[high(MyTimerThread)].f_is_ap_repeater := false;
      MyTimerThread[high(MyTimerThread)].PredvPing := chkPredvPing.Checked;
      MyTimerThread[high(MyTimerThread)].f_is_collect_net_stat := false;
      MyTimerThread[high(MyTimerThread)].PeriodOprosa := edtPeriodOprosa.Value;
      MyTimerThread[high(MyTimerThread)].PeriodUnreachble := edtPingUnreachble.Value;
      MyTimerThread[high(MyTimerThread)].FreeOnTerminate := free_on_term;
      MyTimerThread[high(MyTimerThread)].Start;
      //sleep(8);
      //Application.ProcessMessages;
      //Sleep(random(80));
      //Application.ProcessMessages;
      Query.Next;
    end;
    Query.Close;

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
  Inc(CountThreads);
  MySyncThread.FreeOnTerminate := free_on_term;
  MySyncThread.Start;

  My_timer_5min := TMyTimer5minThread.Create(true);
  Inc(CountThreads);
  My_timer_5min.FreeOnTerminate := free_on_term;
  My_timer_5min.Start;
  //MyThreadTimerWifiOff := TThreadTimerWifiOff.Create(true);
  //MyThreadTimerWifiOff.FreeOnTerminate := free_on_term;
  //LogError := Memo1.Lines;
  //LogError.Clear;
  //if FileExists(ExtractFilePath(Application.ExeName)+'LogError.txt') then
   // LogError.LoadFromFile(ExtractFilePath(Application.ExeName)+'LogError.txt')
  //else
    //LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
   if FileExists(LogFileName) then Memo1.Lines.LoadFromFile(LogFileName);
   Memo1.Perform(EM_LINESCROLL,0,Memo1.Lines.Count-1);
//  sleep(100);
{  if chkSmotr2.Checked then
    MyThreadTimerWifiOff.Start;}
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'InitThreads done.');
  GlobCritSect.Leave;
  fl_threadsDestroyed := False;
  lblCountThreads.Caption := '����� �������: '+IntToStr(CountThreads);
  ADOConnection1.Close;
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
  stats_lte.Close;
  stats_ping.Close;
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
  if not stats_lte.Active then stats_lte.Open;
  if not stats_ping.Active then stats_lte.Open;

  statss_local.EmptyDataSet;
  stats_ap_local.EmptyDataSet;
  stats_lte.EmptyDataSet;
  stats_ping.EmptyDataSet;

  Label4.Caption := IntToStr(statss_local.RecordCount);
  Label5.Caption := IntToStr(stats_ap_local.RecordCount);
  Label9.Caption := IntToStr(stats_lte.RecordCount);
  lblCountPing.Caption := IntToStr(stats_ping.RecordCount);

  statss_local.SaveToFile();
  stats_ap_local.SaveToFile();
  stats_lte.SaveToFile();
  stats_ping.SaveToFile();

  statss_local.Close;
  stats_ap_local.Close;
  stats_lte.Close;
  stats_ping.Close;

end;

procedure TForm1.N5Click(Sender: TObject);
begin
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Exiting...');
  GlobCritSect.Leave;
  Close;
end;

procedure TForm1.btnStopSborClick(Sender: TObject);
var i: integer;
begin

  btnStopSbor.Enabled := false;
  Cursor := crHourGlass;
  Application.ProcessMessages;

  DestroyThreads;

  btnStartSbor.Enabled := true;
  Cursor := crDefault;
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

procedure TForm1.btnStartSborClick(Sender: TObject);
begin
  btnStartSbor.Enabled := false;
  Cursor := crHourGlass;

  InitThreads;
  Application.ProcessMessages;
  btnStopSbor.Enabled := true;
  Cursor := crDefault;
  chkPredvPing.Enabled := false;
  chCollectStatsBullet.Enabled := false;
  edtSnmpTimeout.Enabled := false;
  edtPingUnreachble.Enabled := false;
  edtPeriodOprosa.Enabled := false;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
{  if MyThreadTimerWifiOff.Suspended then begin
    MyThreadTimerWifiOff.Start;
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
  stats_lte.Close;
  stats_ping.Close;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
    if not Assigned(VarMoveToStatssOld) then begin
       VarMoveToStatssOld := TMoveToStatss_oldThreadThread.Create(true);
       VarMoveToStatssOld.FreeOnTerminate := free_on_term;
       VarMoveToStatssOld.Start;
       Button6.Caption := 'Stop MoveToStatss_oldThread';
    end
    else begin
      Button6.Caption := 'Start MoveToStatss_oldThread';
      VarMoveToStatssOld.Terminate;
      if not free_on_term then begin
        VarMoveToStatssOld.WaitFor;
        FreeAndNil(VarMoveToStatssOld);
      end;
    end;
end;

procedure TForm1.DestroyThreads;
var
  i: word;
begin
if  fl_threadsDestroyed then exit;
try
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying My_timer_5minThread begin');
  GlobCritSect.Leave;
  if Assigned(My_timer_5min) then
  begin
    My_timer_5min.Terminate;
    if not free_on_term then begin
      My_timer_5min.WaitFor;
      My_timer_5min.Free;
    end;
  end;
  dec(CountThreads);
  lblCountThreads.Caption := '����� �������: '+IntToStr(CountThreads);
  Application.ProcessMessages;
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying My_timer_5minThread end');
  GlobCritSect.Leave;

 if Length(MyTimerThread)>0 then
  begin
   GlobCritSect.Enter;
   SaveLogToFile(LogFileName,'Destroing modem''s threads begin');
   GlobCritSect.Leave;
   for i := 0 to High(MyTimerThread) do
    if Assigned(MyTimerThread[i]) then begin
      MyTimerThread[i].Terminate;
      if not free_on_term then begin
        MyTimerThread[i].WaitFor;
        MyTimerThread[i].Free;
      end;

      dec(CountThreads);
      lblCountThreads.Caption := '����� �������: '+IntToStr(CountThreads);
      Application.ProcessMessages;
    end;
   SetLength(MyTimerThread,0);
   GlobCritSect.Enter;
   SaveLogToFile(LogFileName,'Destroing modem''s threads end');
   GlobCritSect.Leave;
  end;

  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying SyncThread begin');
  GlobCritSect.Leave;
  if Assigned(MySyncThread) then MySyncThread.Terminate;
  dec(CountThreads);
  lblCountThreads.Caption := '����� �������: '+IntToStr(CountThreads);
  Application.ProcessMessages;
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying SyncThread end');

  SaveLogToFile(LogFileName,'Destroying MoveToStatssOldThread begin');
  GlobCritSect.Leave;
    if Assigned(VarMoveToStatssOld) then begin
      VarMoveToStatssOld.Terminate;
      if not free_on_term then begin
        VarMoveToStatssOld.WaitFor;
        VarMoveToStatssOld.Free;
      end;
    end;
    dec(CountThreads);
  lblCountThreads.Caption := '����� �������: '+IntToStr(CountThreads);
  Application.ProcessMessages;
  GlobCritSect.Enter;
  SaveLogToFile(LogFileName,'Destroying MoveToStatssOldThread end');
  GlobCritSect.Leave;

  {  if Assigned(MyThreadTimerWifiOff) then  begin
    MyThreadTimerWifiOff.Terminate;
    if MyThreadTimerWifiOff.Suspended then MyThreadTimerWifiOff.Start;
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
  RxTrayIcon.Active := false;
  ShowWindow(Application.Handle,SW_SHOW);
  ShowWindow(Handle,SW_SHOW);
  Application.Restore;
  Application.BringToFront;
end;

end.


