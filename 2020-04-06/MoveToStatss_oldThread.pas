unit MoveToStatss_oldThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util,ADODB, MyUtils;

type
  TMoveToStatss_oldThreadThread = class(TThread)
  private
    AQuery: TADOQuery;
    AConn: TADOConnection;
  protected
    procedure DoWork;
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
  AQuery := TADOQuery.Create(Application);
  AConn := TADOConnection.Create(Application);
  AConn.ConnectionString := 'Provider=MSDASQL.1;Persist Security Info=False;Data Source=mysql_ubiquiti';
  AConn.Provider := 'MSDASQL.1';
  AConn.LoginPrompt := false;
  AQuery.Connection := AConn;
  AConn.Close;
end;

destructor TMoveToStatss_oldThreadThread.Destroy;
begin
   AQuery.Close;AQuery.Connection := nil;
   FreeAndNil(AQuery);
   AConn.Close; FreeAndNil(AQuery);
  inherited;
end;

procedure TMoveToStatss_oldThreadThread.DoWork;
var
  date_old: TDateTime;
begin
try
    //в 5 утра удаляем данные старше 70 дней
       date_old:=date - 70;//70 days

       AQuery.Close;
       AQuery.SQL.Text := 'delete from statss where date <= '+QuotedStr(FormatDateTime('yyyy-mm-dd',date_old))+
        ' LIMIT 50000';
       try
         AQuery.ExecSQL;
         AQuery.Close;
       except
        on E:Exception do
        begin
         GlobCritSect.Enter;
         SaveLogToFile(LogFileName,'Ошибка при выполнении '+AQuery.SQL.Text+' в потоке удаления старых данных'+' ('+E.ClassName+': '+E.Message+')');
         GlobCritSect.Leave;
         AQuery.Close;
        end;
       end;

       AQuery.SQL.Text := 'delete from stats_ap where date <= '+QuotedStr(FormatDateTime('yyyy-mm-dd',date_old))+
                 ' LIMIT 15000';
       try
         AQuery.ExecSQL;
         AQuery.Close;
       except
        on E:Exception do
        begin
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
    //20 minutes
   begin_tick := GetTickCount;
   //прерываемый sleep на 20 минут
   while GetTickCount - begin_tick < 1200000 do if not Terminated then sleep(10) else break;
   if (StrToInt(FormatDateTime('h',now)) in [5,6,7])and(not Terminated) then DoWork;
  until Terminated;
end;

end.

