unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI, DBXpress, Provider, SqlExpr, DB, DBClient,
  DBLocal, DBLocalS, Grids, DBGrids, TTDBGrid, FMTBcd, ExtCtrls, RXShell, MyTimer,
  ADODB, SyncThread, MoveToStatss_oldThread, Menus;// DelphiCryptlib, cryptlib;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    RxTrayIcon1: TRxTrayIcon;
    Query: TADOQuery;
    ADOConnection1: TADOConnection;
    Timer1: TTimer;
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
    procedure RxTrayIcon1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Hide_appl(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button33Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
//    function SSH_Client(Server, Userid, Pass: string): TCryptSession;
//    function GetSSHstring(FIp, FUser,FPasswd, FCmd: string): string;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;



var
  Form1: TForm1;
  MyTimerThread: Array of TMyTimerThread;
  MySyncThread: TMySyncThread;
  VarMoveToStatssOld: TMoveToStatss_oldThreadThread;
  ArrayID, LogError: TStrings;

implementation

{$R *.dfm}

(* function TForm1.SSH_Client(Server, Userid, Pass: string): TCryptSession;
begin
 result := TCryptSession.Create(CRYPT_SESSION_SSH);
 with result do begin
   ServerName := Server;  { set hostname or IP address }
   UserName := Userid;    { set user identification }
   Password := Pass;      { set password }
 end;
 try
   result.Activate;       { establish SSH connection to server }
 except
   on E: ECryptError do
   begin
     //Memo11.Add(E.Message);
     FreeAndNil(result);
   end;
 end;
end; *)

procedure TForm1.RxTrayIcon1DblClick(Sender: TObject);
begin
  RxTrayIcon1.Active := false;
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
      if (Modemsip_address.AsString='10.70.120.98')or(Modemsis_access_point.AsInteger=1) then MyTimerThread[high(MyTimerThread)].status_default := 2
      else MyTimerThread[high(MyTimerThread)].status_default := 0;
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
  VarMoveToStatssOld := TMoveToStatss_oldThreadThread.Create(false);
  LogError := Memo1.Lines;
  LogError.Clear;
  if FileExists(ExtractFilePath(Application.ExeName)+'LogError.txt') then
    LogError.LoadFromFile(ExtractFilePath(Application.ExeName)+'LogError.txt')
  else
    LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
end;

procedure TForm1.Hide_appl(Sender: TObject);
begin
  RxTrayIcon1.Active := true;
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
      MyTimerThread[i].Terminate;
    end;
  if Assigned(MySyncThread) then begin
    MySyncThread.Terminate;
  end;
  if Assigned(VarMoveToStatssOld) then  begin
    VarMoveToStatssOld.Terminate;
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

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if LogError.Count > 5000 then
  begin
    LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogErrorOld'+
      FormatDateTime('yyyymmdd-hhnnss',now)+'.txt');
    LogError.Clear;
    LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
  Memo1.Lines.Clear;
  Label2.Caption := IntToStr(LogError.Count);
  try
    if statss_local.RecordCount>5000 then statss_local.SaveToFile;
  except
    LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении statss_local.SaveToFile в основном модуле');
    LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
  end;
end;

procedure TForm1.Button33Click(Sender: TObject);
begin
  statss_local.First;
  while statss_local.RecordCount>0 do statss_local.Delete;
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
end;

(* function TForm1.GetSSHstring(FIp, FUser, FPasswd, FCmd: string): string;
type TArrayString = array [0..254] of AnsiChar;
var
 SSH: TCryptSession;
//  Data: PAnsiChar;
 Data: TArrayString;
 DataString: string;
 LenData: Integer;
 BytePushed: Integer;
 BytePoped: Integer;

begin

 cryptInit;
 SSH := SSH_Client(FIp, FUser, FPasswd);
 if SSH = nil then
   Exit;

 SSH.FlushData; // обязательно нужно использовать перед вызовом PopData

 Sleep(500);
 LenData := 255;
 FillChar(Data,255,#0);
 BytePoped := SSH.PopData(addr(Data), LenData);
 FillChar(Data,255,#0);
   DataString := Fcmd+#13;
   move(Datastring[1],Data,Length(DataString));
 LenData := length(DataString);
 SSH.PushData(addr(Data), LenData, BytePushed);
 SSH.FlushData;
 Sleep(500);

 LenData := 255;
 FillChar(Data,255,#0);
 BytePoped := SSH.PopData(addr(Data), LenData);
 Result := Data;

 FreeAndNil(SSH);
 cryptEnd;
 sleep(100);
end;     *)

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if MessageDlg('Exit now?',  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
 begin
   Action := caFree;
   Application.Terminate;
 end;
end;

end.


