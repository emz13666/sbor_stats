unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI, DBXpress, Provider, SqlExpr, DB, DBClient,
  Grids, DBGrids, TTDBGrid, FMTBcd, ExtCtrls, RXShell, MyTimer,
  ADODB, SyncThread, MoveToStatss_oldThread, Menus, ThreadTimerWifiOff;// DelphiCryptlib, cryptlib;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Query: TADOQuery;
    ADOConnection1: TADOConnection;
    Label1: TLabel;
    Label2: TLabel;
    statss_local: TClientDataSet;
    statss_localid: TAutoIncField;
    statss_localid_modem: TIntegerField;
    statss_localmac_ap: TWideStringField;
    statss_localsignal_level: TSmallintField;
    statss_localdate: TDateField;
    statss_localtime: TTimeField;
    statss_localstatus: TSmallintField;
    statss_localx: TSmallintField;
    statss_localy: TSmallintField;
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
    Modemsid_modem: TLargeintField;
    Modemsname: TWideStringField;
    Modemsip_address: TWideStringField;
    Modemsequipment_type: TIntegerField;
    ModemsuseInMonitoring: TSmallintField;
    Modemsis_access_point: TSmallintField;
    QueryWifi_log: TADOQuery;
    ConnectionWifi_log: TADOConnection;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Modemsfirmware: TWideStringField;
    RxTrayIcon1: TTrayIcon;
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
  private
    { Private declarations }
  public
    { Public declarations }
  end;



var
  Form1: TForm1;
  MyThreadTimerWifiOff: TThreadTimerWifiOff;
  MyTimerThread: Array of TMyTimerThread;
  MySyncThread: TMySyncThread;
  VarMoveToStatssOld: TMoveToStatss_oldThreadThread;
  LogError: TStrings;

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
  statss_local.FileName := ExtractFilePath(Application.ExeName)+'statss_local.cds';
  statss_local.Open;
  statss_local.LogChanges := false;

  Label4.Caption := IntToStr(statss_local.RecordCount);
  Application.OnMinimize := Hide_appl;
  try
    Modems.Open;
    while not Modems.Eof do
    begin
      SetLength(myTimerThread,Length(MyTimerThread)+1);
      MyTimerThread[high(MyTimerThread)] := TMyTimerThread.Create(true);
      MyTimerThread[high(MyTimerThread)].f_host := Modemsip_address.AsString;
      MyTimerThread[high(MyTimerThread)].F_IDModem := Modemsid_modem.AsString;
      if (Modemsequipment_type.AsInteger=3) then MyTimerThread[high(MyTimerThread)].status_default := 2
        else MyTimerThread[high(MyTimerThread)].status_default := 0;
      if (Modemsfirmware.AsString='5.5') then MyTimerThread[high(MyTimerThread)].f_new := false
        else MyTimerThread[high(MyTimerThread)].f_new := true;
      MyTimerThread[high(MyTimerThread)].f_is_access_point := (Modemsis_access_point.AsInteger=1);
      MyTimerThread[high(MyTimerThread)].Resume;
      Modems.Next;
    end;
    modems.Close;
  except
    ShowMessage('Невозможно инициализировать потоки - нет доступа к СУБД');
    Application.Terminate;
  end;
  MySyncThread := TMySyncThread.Create(true);
  MySyncThread.Resume;
  MyThreadTimerWifiOff := TThreadTimerWifiOff.Create(true);
  VarMoveToStatssOld := TMoveToStatss_oldThreadThread.Create(true);
  VarMoveToStatssOld.Resume;
  LogError := Memo1.Lines;
  LogError.Clear;
  if FileExists(ExtractFilePath(Application.ExeName)+'LogError.txt') then
    LogError.LoadFromFile(ExtractFilePath(Application.ExeName)+'LogError.txt')
  else
    LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  sleep(100);
  MyThreadTimerWifiOff.Resume;
end;

procedure TForm1.Hide_appl(Sender: TObject);
begin
  RxTrayIcon1.Visible := true;
  Application.Minimize;
  //Application.ShowMainForm := false;
  ShowWindow(Application.Handle,SW_HIDE);
//  ShowWindow(Application.MainForm.Handle,SW_HIDE);
end;


procedure TForm1.FormActivate(Sender: TObject);
begin
  Hide_appl(@Self);
end;

procedure TForm1.FormDestroy(Sender: TObject);
var i: byte;
begin
  for i := 0 to High(MyTimerThread) do
    if Assigned(MyTimerThread[i]) then begin
      if MyTimerThread[i].Suspended then MyTimerThread[i].Resume;
      MyTimerThread[i].Terminate;
      MyTimerThread[i].WaitFor;
      MyTimerThread[i].Free;
    end;
  SetLength(MyTimerThread,0);
  if Assigned(MySyncThread) then begin
    if MySyncThread.Suspended then MySyncThread.Resume;
    MySyncThread.Terminate;
    MySyncThread.WaitFor;
    MySyncThread.Free;
  end;
  if Assigned(VarMoveToStatssOld) then  begin
    if VarMoveToStatssOld.Suspended then VarMoveToStatssOld.Resume;
    VarMoveToStatssOld.Terminate;
    VarMoveToStatssOld.WaitFor;
    VarMoveToStatssOld.Free;
  end;
  if Assigned(MyThreadTimerWifiOff) then  begin
    MyThreadTimerWifiOff.Terminate;
    MyThreadTimerWifiOff.WaitFor;
    MyThreadTimerWifiOff.Free;
  end;

//  statss_local.SaveToFile;
  statss_local.Close;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogErrorOld'+
      FormatDateTime('yyyymmdd-hhnnss',now)+'.txt');
  LogError.Clear;
  LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  Label2.Caption := '000';
end;

procedure TForm1.Button33Click(Sender: TObject);
begin
  statss_local.EmptyDataSet;
  Label4.Caption := IntToStr(statss_local.RecordCount);
  statss_local.SaveToFile();
  statss_local.Close;
//  statss_local.LoadFromFile;
end;

procedure TForm1.N5Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button2Click(Sender: TObject);
var i: integer;
begin
  for i := 0 to High(MyTimerThread) do
      MyTimerThread[i].Suspend;
    MySyncThread.Suspend;
    VarMoveToStatssOld.Suspend;
  statss_local.SaveToFile();
  Button2.Enabled := false;
  Button3.Enabled := true;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if MessageDlg('Exit now?',  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
 begin
   Action := caFree;
   Application.Terminate;
 end;
end;

procedure TForm1.Memo1Change(Sender: TObject);
begin
  Label2.Caption := IntToStr(LogError.Count);
end;

procedure TForm1.Button3Click(Sender: TObject);
var i: integer;
begin
  for i := 0 to High(MyTimerThread) do
      MyTimerThread[i].resume;
    MySyncThread.Resume;
    VarMoveToStatssOld.Resume;
  Button3.Enabled := false;
  Button2.Enabled := true;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if MyThreadTimerWifiOff.Suspended then begin
    MyThreadTimerWifiOff.Resume;
    Button4.Caption := 'Stop_checkWIFI';
  end
  else begin
    Button4.Caption := 'Start_checkWIFI';
    MyThreadTimerWifiOff.Suspend;
  end;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  statss_local.Close;
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


