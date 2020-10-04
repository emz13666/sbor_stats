unit SSH_wifi;

interface

uses Forms, Classes, SysUtils, DelphiCryptlib, cryptlib;

type TSSHobj=class
    Fbusy : boolean;

  private
    hellostr: string;
    function SSH_Client(Server, Userid, Pass: string): TCryptSession;
    function execSSHCommand(command: shortString): boolean;
  public
    SSH:TCryptSession;
    Answer: TStrings;
    FSleepTm:integer;
    FCommand:shortString;
    property busy: boolean read FBusy;
    function Lock : boolean;
    procedure Unlock;
    constructor Create(FIP,FLogin,FPass,Fhellostr: string);
    destructor Destroy; override;
    function Execute : boolean;
end;

function GetWord(Str, Smb: string; WordNmbr: Byte): string;

// Ќайти первый индекс строки списка, в которую входит подстрока. ¬озвращает номер строки списка или -1, если не найден
function FindLineSubstringInList(substring:string;var List:TStrings ):integer;


implementation

function FindLineSubstringInList( substring:string;var List:TStrings ):integer; // Ќайти первый индекс строки списка, в которую входит подстрока. ¬озвращает номер строки списка или -1, если не найден
begin
for Result := 0 to List.Count - 1 do
    if pos(substring, List[result]) <> 0 then Exit;
  Result := -1;
end;


{ TSSHobj }

constructor TSSHobj.Create(FIP,FLogin,FPass,Fhellostr: string);
begin
     inherited Create;
     hellostr := Fhellostr;
     SSH:=SSH_Client(FIP,FLogin,FPass);
     Answer:=TStringList.Create;
     Answer.Clear;
     FSleepTm:=600;
     execSSHCommand(#13);
end;

destructor TSSHobj.Destroy;
begin
     FreeAndNil(SSH);
     Answer.Free;
     inherited;
end;

// ‘ункци€ выполнени€ команды и получение данных от выполнени€ по SSH дл€ текущей сессии SSH
function TSSHobj.execSSHCommand(command: shortString): boolean;
type TArrayString = array [0..254] of AnsiChar;
var
  LenData,LenData1, cnt1, i2,i3: Integer;
  BytePushed: Integer;
  BytePoped: Integer;
  data:TArrayString;
  dataString,tmpstr:ShortString;
  sleeptm1:integer;
  diffsleep:integer;
  countretries:word;
  currentretries:word;
  findhello:boolean;
begin
      sleeptm1:=20;
      countretries:=10;
      if FSleepTm<300 then FSleepTm:=300;
      diffsleep:=round(FSleepTm / countretries);
      result:=false;
      if SSH = nil then Exit;
      // ќчищает буфер вывода
      SSH.FlushData; // об€зательно нужно использовать перед вызовом PopData
      Sleep(sleeptm1);
      LenData := 255;
      FillChar(Data,255,#0);
      // ѕолучаем строку приветстви€ сервера
      BytePoped := SSH.PopData(addr(Data), LenData);
      sleep(sleeptm1);
      currentretries:=0;
      tmpstr:='';
      i2:=0;
      // ¬озможно в дальнейшем нужно будет просто дождатьс€ возвращени€ пустого набора данных
      while (data[i2]<>#0) do begin
          tmpstr:=tmpstr+data[i2];
          inc(i2);
      end;
      if tmpstr='' then findhello:=true
          else findhello:=pos(hellostr,tmpstr)>0;
      while (not findhello) and (currentretries<countretries) do begin
            inc(currentretries);
            Sleep(diffsleep);
            BytePoped := SSH.PopData(addr(Data), LenData);
            sleep(sleeptm1);
            i2:=0;
            while (data[i2]<>#0) do begin
                tmpstr:=tmpstr+data[i2];
                inc(i2);
            end;
            findhello:=pos(hellostr,tmpstr)>0;
      end;
      if currentretries=countretries then begin
         Result:=false;
         exit;
      end;
      // «аполн€ем переменную данных нул€ми
      FillChar(Data,255,#0);
      dataString:=command;
      // ≈сли команда была передана без символа окончани€ строки, то добавл€ем этот символ
      if datastring[length(datastring)-1]<>#13 then dataString:=dataString+#13;
      // ¬тора€ #13 нужна дл€ того, чтобы после результата получили строку приветстви€
      dataString:=datastring+#13;
      move(Datastring[1],Data,Length(DataString));
      LenData := length(DataString);
      // ќтправка команды на сервер
      SSH.PushData(addr(Data), LenData, BytePushed);
      sleep(sleeptm1 div 5);
      while (BytePushed<LenData) and (currentretries<countretries) do begin
            inc(currentretries);
            Sleep(diffsleep);
      end;
      if currentretries=countretries then begin
         Result:=false;
         exit;
      end;
      SSH.FlushData;
      sleep(sleeptm1);

      //извлекаем сначала то что запушили ранее (выполн€емые команды)
      FillChar(Data,255,#0);
      BytePoped := SSH.PopData(addr(Data), LenData+1);
      sleep(sleeptm1);
      if Not Assigned(Answer) then Answer:=TStringList.Create;
      Answer.Clear;
      tmpstr:='';
      LenData := 1;
      FillChar(Data,255,#0);
      BytePoped := SSH.PopData(addr(Data), LenData);
      //sleep(sleeptm1);
      while ((BytePoped > 0) or (currentretries<countretries)) and ( not result) do begin
              if BytePoped>0 then begin
                  if (Data[0]<>#13)and(Data[0]<>#10) then tmpStr:= tmpStr+Data[0]
                  else
                  begin
                       if Data[0]=#13 then begin
                          findhello:=Pos(hellostr,tmpstr)>0;
                          if (not findhello) then Answer.Add(tmpstr);
                          // “ак как последней строкой должно быть lgkdisp:~$,
                          // то если текуща€ строка соответствует ей, то проставл€ть флаг корректности
                          if findhello and (length(tmpstr)<=12) then begin
                              result:=true;
                          end else begin
                              result:=false;
                          end;
                       end;
                       tmpStr := '';
                  end;
              end else begin
                  // ≈сли нет новых символов в очереди, то провер€ем, не получили ли правильный вывод
                  if pos(hellostr,tmpstr)>0 then begin
                      result:=true;
                      continue;
                  end;
                  inc(currentretries);
                  sleep(diffsleep);
                  //continue;
                  //SSH.FlushData;
                  //sleep(sleeptm1 div 2);
              end;
              FillChar(Data,1,#0);
              BytePoped := SSH.PopData(addr(Data), LenData);
              //sleep(sleeptm1 div 5);
      end;
      //if pos('lgkdisp:~$',tmpstr)>0 then result:=true;
      //if not Result then sleep(timeout);
end;

function TSSHobj.Execute: boolean;
begin
     result:=execSSHCommand(FCommand);
end;

function TSSHobj.Lock : boolean;
var slp,cnt:integer;
begin
     slp:=100;
     cnt:=0;
     while FBusy and (cnt<100) do begin
         inc(cnt);
         sleep(slp);
     end;
     if not FBusy then begin
        Fbusy:=true;
        result:=true;
     end else result:=false;
end;

function TSSHobj.SSH_Client(Server, Userid, Pass: string): TCryptSession;
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
     Application.MessageBox(PChar(E.Message),'Connnection error');
     FreeAndNil(result);
   end;
 end;
end;

procedure TSSHobj.Unlock;
begin
      Fbusy:=false;
end;

function GetWord(Str, Smb: string; WordNmbr: Byte): string;
var
  SWord: string;
  StrLen, N: Byte;
begin

  StrLen := SizeOf(Str);
  N := 1;
    //пропускаем пробелы в начале предложени€
  while (str[1] = smb)and(length(str)>0) do delete(str,1,1);

  while ((WordNmbr >= N) and (StrLen <> 0)) do
  begin
    StrLen := Pos(Smb, str);
    if StrLen <> 0 then
    begin
      SWord := Copy(Str, 1, StrLen - 1);
      Delete(Str, 1, StrLen);
      Inc(N);
    end
    else
      SWord := Str;
  end;

  if WordNmbr <= N then
    Result := SWord
  else
    Result := '';
end;

end.
