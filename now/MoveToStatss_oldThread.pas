unit MoveToStatss_oldThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util,ADODB, MyUtils, Messages;

type
  TMoveToStatss_oldThreadThread = class(TThread)
  private
    AQuery: TADOQuery;
    AConn: TADOConnection;
  protected
    procedure DoWork;
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

    procedure TMyTimerThread.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }



constructor TMoveToStatss_oldThreadThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  AConn := TADOConnection.Create(Application);
  AConn.ConnectionString := 'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql_ubiquiti';
  AConn.Provider := 'MSDASQL.1';
  AConn.LoginPrompt := false;
  AConn.Close;

  AQuery := TADOQuery.Create(Application);
  AQuery.Connection := AConn;
//  AQuery.ExecuteOptions := [eoAsyncExecute];
  AQuery.Close;
end;

destructor TMoveToStatss_oldThreadThread.Destroy;
begin
   AQuery.Close;
   AQuery.Connection := nil;
   FreeAndNil(AQuery);
   AConn.Close;
   FreeAndNil(AConn);
  inherited;
end;

procedure TMoveToStatss_oldThreadThread.DoWork;
var
  date_old: TDateTime;
begin
  if Terminated then Exit;
  try
      //в 5,6,7 утра удаляем данные старше 70 дней
         date_old:=date - 70;//70 days
         AQuery.Close;
//         AQuery.SQL.Text := 'delete from ' + fNameTable + ' where datetime <= '+QuotedStr(FormatDateTime('yyyy-mm-dd 23:59:59',date_old))+
//            ' LIMIT 30000 ';
         AQuery.SQL.Text := 'CALL del_old_from_stats';
      try
             AQuery.ExecSQL;
           except
            on E:Exception do
            begin
            AQuery.Close;
             GlobCritSect.Enter;
             SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке удаления старых данных'+' ('+E.ClassName+': '+E.Message+')');
             GlobCritSect.Leave;
            end;
      end;

  finally
     AQuery.Close;
     AConn.Close;
  end;
end;

procedure TMoveToStatss_oldThreadThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  repeat
   begin_tick := GetTickCount;
   //прерываемый sleep на 59 минут
   while GetTickCount - begin_tick < 59*60*1000 do if not Terminated then sleep(10) else break;
   if (not Terminated)and(StrToInt(FormatDateTime('h',now)) = 5) then begin
      SaveLogToFile(LogFileName,'Очистка старых данных начата.');
      Synchronize(UpdateMemoOnForm);
      DoWork;
      SaveLogToFile(LogFileName,'Очистка старых данных завершена.');
      Synchronize(UpdateMemoOnForm);
   end;
  until Terminated;
end;

procedure TMoveToStatss_oldThreadThread.UpdateMemoOnForm;
begin
  if Terminated then Exit;
  Form1.Memo1.Lines.LoadFromFile(LogFileName);
  Form1.Memo1.Perform(EM_LINESCROLL,0,Form1.Memo1.Lines.Count-1);
end;

end.

