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
  try
      //� 5,6,7 ���� ������� ������ ������ 70 ����
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
             SaveLogToFile(LogFileName,'������ ��� ���������� '+AQuery.SQL.Text+' � ������ �������� ������ ������'+' ('+E.ClassName+': '+E.Message+')');
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
   //����������� sleep �� 8 �����
   while GetTickCount - begin_tick < 8*60*1000 do if not Terminated then sleep(10) else break;
   if (StrToInt(FormatDateTime('h',now)) in [5,6,7])and(not Terminated) then
      DoWork;

  until Terminated;
end;

end.

