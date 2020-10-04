unit MoveToStatss_oldThread;

interface
uses Windows, Classes, forms,snmpsend,asn1util;

type
  TMoveToStatss_oldThreadThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure DoWork;
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



procedure TMoveToStatss_oldThreadThread.DoWork;
var date_old: TDateTime;
begin
    //в 5 утра удаляем данные старше 70 дней
     with form1 do begin
       date_old:=date - 70;//70 days
       Query1.Close;
       Query1.SQL.Text := 'delete from statss where date <= '+QuotedStr(FormatDateTime('yyyy-mm-dd',date_old));
       try
         ADOConnection2.Close;
         ADOConnection2.Open;
         Query1.ExecSQL;
       except
         ADOConnection2.Close;
         mainunit.LogError.Add(FormatDateTime('dd.mm.yyyy hh:mm:ss', now)+'     Ошибка при выполнении '+Query1.SQL.Text+' в потоке удаления старых данных');
         mainunit.LogError.SaveToFile(ExtractFilePath(Application.ExeName)+'LogError.txt');
       end;
       Query1.Close;
       ADOConnection2.Close
     end;
end;

procedure TMoveToStatss_oldThreadThread.Execute;
var begin_tick: cardinal;
begin
  { Place thread code here }
  repeat
    //20 minutes
   begin_tick := GetTickCount;
   while GetTickCount - begin_tick < 1200000 do
      if not Terminated then sleep(10) else break;
    if (FormatDateTime('hh',now)='05')and(not Terminated) then DoWork;
  until Terminated;
end;

end.

