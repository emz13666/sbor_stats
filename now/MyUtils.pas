// Разные полезные методы для работы
unit MyUtils;

interface

uses Windows, sysUtils, shFolder, Classes;
// Работа с еврсией файла
type

  TVersion = record
    MajorVersion: Word;
    MinorVersion: Word;
    Release     : Word;
    Build       : Word;
  end;

  TLanguage = packed record
    Name: string;
    Ext : string;
    case Integer of
      0: (LangID, CharsetID: Word);
      1: (Translation:   Longword);
  end;

  TStringFileInfo = record
    Language        : TLanguage;
    CompanyName     : string;
    FileDescription : string;
    FileVersion     : string;
    InternalName    : string;
    LegalCopyright  : string;
    LegalTrademarks : string;
    OriginalFilename: string;
    ProductName     : string;
    ProductVersion  : string;
    Comments        : string;
    PrivateBuild    : string;
    SpecialBuild    : string;
  end;

  Type TFileInfo=Record
         IsFixedFileInfo : Boolean;
         FixedFileInfo   : TVSFixedFileInfo;
         FileVersion     : TVersion;
         StringFileInfo  : TStringFileInfo;
       End;

  Function GetFileInfo(FileName:String; Var FileInfo:TFileInfo):Boolean;

// Конец работы с версией файла


function LastPos(substr, s:string):integer;
Procedure CopyEXEVersion(ExeName, subfolder:string); // Процедура создания копии ехе файла определенной версии
function DelDoubleSpaces(OldText:String):string;  // Функция для удаления двойных пробелов
function getMonthNumByString(str:string):integer; // Получить номер месяца по 3 буквам названия
Procedure SaveToFile(filename,str:string);        // Процедура записи текста в файл
procedure SaveLogToFile(filename,str:string);     // Сохранение записи в лог-файл с указанием даты и времени
function TimeToShiftSec(tm:TTime):integer;        //Функция получения количества секунд, прошедших с начала смены по фактическому времени tm
function DateToShift(dt:TDate; tm:TTime):integer; // Функция для определения номера смены по дате и времени
function GetShiftindex(dttm:TDateTime):integer;   // Определение номера смены по дате и времени
function ShiftAndSecToDateTime(shiftindex, seconds:integer):TDateTime;  // Функция, преобразуюжая номер смены и количество секунд с начала смены в формат дата время
function MSecondToTime(const miliSeconds: Cardinal): TTime; //Перевести секунды в формат времени
function IsIPAddress(str: string): boolean; // Является ли строка IP Адресом
function DateTimeToTimeStamp1970(dt:TDateTime):Longint; // Определение количества секунд, которые прошли с 01.01.1970 до момента dt
function GetSpecialFolderPath(folder : integer) : string; // Получение пути к специальному каталогу
function ANSI2KOI8R(S: string): string;            // Конвертация из ANSI в KOI8R
function KOI8R2ANSI(S: string): string;            // Конвертация из KOI8R в ANSI
function FindLineSubstringInList( substring:string; List:TStrings ):integer; // Найти первый индекс строки списка, в которую входит подстрока. Возвращает номер строки списка или -1, если не найден
function GetNowstr():string;
function isShiftName(shiftname:string):boolean;     // Является ли строка именем смены
function DateTimeToShiftName(dttm:TDateTime):string; // Получение имени сменн по дате и времени
function ShiftNameToDateTime(shiftname:string):TDateTime;      // Получение даты и времени по имени смены
function LinesCount(const Filename: string): Integer;          // Количество строк в текстовом файле
function GetModularStatusName(status:shortint):string;   // Получение названия статуса по номеру
function BooleanToString (FValue: boolean):AnsiString;

implementation

function BooleanToString (FValue: boolean):AnsiString;
begin
  if FValue then Result := 'True'
  else Result := 'False';
end;

Function GetFileInfo(FileName:String; Var FileInfo:TFileInfo):Boolean;
      var I, J: Integer;
          S: string;

          AFileName: string;

          InfoSize, InfoHandle: DWORD;
          InfoBuf: Pointer;

          ItemBuf: Pointer;
          ItemSize: UINT;

          pDW: PDWORD;
    begin
      Result:=False;
      FileInfo.IsFixedFileInfo := False;
      try
      Finalize(FileInfo.StringFileInfo);

      AFileName := FileName;

      InfoSize := GetFileVersionInfoSize(PChar(AFileName), InfoHandle);

      if InfoSize <> 0 then
        begin
          GetMem(InfoBuf, InfoSize);
          try
            if GetFileVersionInfo(PChar(AFileName), InfoHandle, InfoSize, InfoBuf) then
              begin
                if VerQueryValue(InfoBuf, '\', ItemBuf, ItemSize) then
                  begin
                    FileInfo.FixedFileInfo := PVSFixedFileInfo(ItemBuf)^;
                    FileInfo.IsFixedFileInfo := True;
                  end;

                if VerQueryValue(InfoBuf, '\VarFileInfo\Translation', ItemBuf, ItemSize) then
                  begin
                    pDW := ItemBuf;
                    with FileInfo.StringFileInfo do
                      begin
                        Result:=True;
                        Language.Translation := pDW^;

                        S := Format('\StringFileInfo\%.4x%.4x\', [Language.LangID, Language.CharsetID]);

                        if VerQueryValue(InfoBuf, PChar(S + 'CompanyName'     ), ItemBuf, ItemSize) then
                        CompanyName      := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'FileDescription' ), ItemBuf, ItemSize) then
                        FileDescription  := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'FileVersion'     ), ItemBuf, ItemSize) then
                        FileVersion      := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'InternalName'    ), ItemBuf, ItemSize) then
                        InternalName     := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'LegalCopyright'  ), ItemBuf, ItemSize) then
                        LegalCopyright   := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'LegalTrademarks' ), ItemBuf, ItemSize) then
                        LegalTrademarks  := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'OriginalFilename'), ItemBuf, ItemSize) then
                        OriginalFilename := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'ProductName'     ), ItemBuf, ItemSize) then
                        ProductName      := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'ProductVersion'  ), ItemBuf, ItemSize) then
                        ProductVersion   := PChar(ItemBuf);

                        if VerQueryValue(InfoBuf, PChar(S + 'Comments'        ), ItemBuf, ItemSize) then
                        Comments         := PChar(ItemBuf);

                        if FileInfo.IsFixedFileInfo then
                          begin
                            if FileInfo.FixedFileInfo.dwFileFlags and VS_FF_PRIVATEBUILD <> 0 then
                            if VerQueryValue(InfoBuf, PChar(S + 'PrivateBuild'), ItemBuf, ItemSize) then
                            PrivateBuild := PChar(ItemBuf);

                            if FileInfo.FixedFileInfo.dwFileFlags and VS_FF_SPECIALBUILD <> 0 then
                            if VerQueryValue(InfoBuf, PChar(S + 'SpecialBuild'), ItemBuf, ItemSize) then
                            SpecialBuild := PChar(ItemBuf);
                          end;
                      end;
                  end;
              end; // if GetFileVersionInfo
          finally
            FreeMem(InfoBuf);
          End;
        end;// if InfoSize <> 0
      with FileInfo do
        begin
          FileVersion.MajorVersion := HIWORD(FixedFileInfo.dwFileVersionMS);
          FileVersion.MinorVersion := LOWORD(FixedFileInfo.dwFileVersionMS);
          FileVersion.Release      := HIWORD(FixedFileInfo.dwFileVersionLS);
          FileVersion.Build        := LOWORD(FixedFileInfo.dwFileVersionLS);
        end;
      except
         result:=false;
      end;
    end;

// Последнее вхождение подстроки в строку
function LastPos(SubStr, S: string): Integer;
var   Found, Len, Pos: integer;
begin
  Pos := Length(S);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do   begin
      if Copy(S, Pos, Len) = SubStr then Found := Pos;
      Dec(Pos);
  end;
  LastPos := Found;
end;

// Процедура создания копии exe файла в папке с проектом
Procedure CopyEXEVersion(ExeName, subfolder:string);
var progDir, filename,newfilename:string;
    finfo:TFileInfo;
    posdot:integer;
begin
     progDir:=ExtractFileDir(ExeName);
     if not DirectoryExists(progdir+'\'+subfolder) then CreateDir(progdir+'\'+subfolder);
     if GetFileInfo(ExeName,fInfo) then begin
        FileName:=ExtractFileName(ExeName);
        posDot:=pos('.',filename);
        newfileName:=progdir+'\'+subfolder+'\'+Copy(filename,1,posdot-1)+'_'+inttostr(finfo.FileVersion.MajorVersion)+'_'+inttostr(finfo.FileVersion.MinorVersion)+'_'+inttostr(finfo.FileVersion.Release)+Copy(filename,posdot,length(filename)-(posdot-1));
     end;
     //if FileExists(newfileName) then DeleteFile(newfileName);
     if not FileExists(newfileName) then CopyFile(PWideChar(ExeName),PWideChar(newfilename),false);
end;

// Функция для удаления двойных пробелов
function DelDoubleSpaces(OldText:String):string;
var i:integer;
     s:string;
begin
  if length(OldText)>0 then
    s:=OldText[1]
  else
    s:='';
  for i:=1 to length(OldText) do
  begin
    if OldText[i]=' ' then
    begin
      if not (OldText[i-1]=' ') then
        s:=s+' ';
    end
    else
    begin
      s:=s+OldText[i];
    end;
  end;
  DelDoubleSpaces:=s;
end;

// Получаем номер месяца по трем буквам названия
function getMonthNumByString(str:string):integer;
var s:string;
begin
  s:=ANSILowerCase(str);
  result:=0;
  if pos('jan',s)>0 then result:=1;
  if pos('feb',s)>0 then result:=2;
  if pos('mar',s)>0 then result:=3;
  if pos('apr',s)>0 then result:=4;
  if pos('may',s)>0 then result:=5;
  if pos('jun',s)>0 then result:=6;
  if pos('jul',s)>0 then result:=7;
  if pos('aug',s)>0 then result:=8;
  if pos('sep',s)>0 then result:=9;
  if pos('oct',s)>0 then result:=10;
  if pos('nov',s)>0 then result:=11;
  if pos('dec',s)>0 then result:=12;
end;

// Функция записи текста в файл
Procedure SaveToFile(filename,str:string);
var f:Text;
begin
  try
    AssignFile(f,filename);
    if not FileExists(filename) then begin
       Rewrite(f);
       CloseFile(f);
    end;
    Append(f);
    Writeln(f,str);
    Flush(f);
    CloseFile(f);
   except
     CloseFile(f);
   end;
{var    memo11:TStrings;
memo11 := TStringList.create;
memo11.Loadfromfile(filename)
memo.ad
memo.free}
end;

procedure SaveLogToFile(filename,str:string);
begin
     str:=GetNowStr+': '+str;
     SaveToFile(filename,str);
end;

//Функция получения количества секунд, прошедших с начала смены по фактическому времени tm
function TimeToShiftSec(tm:TTime):integer;
var tm1:TTime;
begin
     if tm>=strtotime('7:30') then tm1:=tm-StrToTime('7:30') else tm1:=tm+StrToTime('4:30');
     if tm1>=StrToTime('12:00') then tm1:=tm1-StrToTime('12:00');
     // 86400 - количество секунд в сутках
     result:=round(tm1*86400);
end;

// Функция для определения номера смены по дате и времени
function DateToShift(dt:TDate; tm:TTime):integer;
var shift:integer;
begin
         shift:=round((int(dt)-int(strToDate('01.01.1970')))*2);
         if tm>=StrToTime('7:30') then shift:=shift+1;
         if tm>=StrToTime('19:30') then shift:=shift+1;
         result:=shift;
end;

function GetShiftindex(dttm:TDateTime):integer;
var dt:TDate;
    tm:TTime;
begin
    dt:=trunc(dttm);
    tm:=dttm-dt;
    result:=DateToShift(dt,tm);
end;

// Функция, преобразуюжая номер смены и количество секунд с начала смены в формат дата время
function ShiftAndSecToDateTime(shiftindex, seconds:integer):TDateTime;
begin
  result:=strToDate('01.01.1970')-StrToTime('4:30')+(shiftindex/2)+(1/24/3600*seconds);
end;

//Перевести секунды в формат времени
function MSecondToTime(const miliSeconds: Cardinal): TTime;
const  MSecPerDay = 86400000;
  MSecPerHour = 3600000;
  MSecPerMinute = 60000;
  MSecPerSec = 1000;
var
  ms, ss, mm, hh, dd: Cardinal;
begin
  dd := miliSeconds div MSecPerDay;
  hh := (miliSeconds mod MSecPerDay) div MSecPerHour;
  mm := ((miliSeconds mod MSecPerDay) mod MSecPerHour) div MSecPerMinute;
  ss := (((miliSeconds mod MSecPerDay) mod MSecPerHour) mod MSecPerMinute) div MSecsPerSec;
  ms := (((miliSeconds mod MSecPerDay) mod MSecPerHour) mod MSecPerMinute) mod MSecsPerSec;
  Result := EncodeTime(hh, mm, ss, ms);
end;

// Является ли строка IP Адресом
function IsIPAddress(str: string): boolean;
var pos1,copyindex,deleteindex:integer;
    str1 : string;
    digit:integer;
    countDigit:shortint;
begin
     str1:=str;
     result:=true;
     countDigit:=0;
     while result and (length(str1)>0) do begin
          pos1:=pos('.',str1);
          if pos1>0 then begin
             copyindex:=pos1-1;
             deleteindex:=pos1;
          end else begin
             copyindex:=Length(str1);
             deleteindex:=Length(str1);
          end;
          try
             digit:=strtoint(copy(str1,1,copyindex));
             if (digit<0) or (digit>255) then result:=false;
          except
             result:=false;
          end;
          inc(countDigit);
          Delete(str1,1,deleteindex);
     end;
     if countDigit<>4 then result:=false;
end;

// Определение количества секунд, прошедших с 01.01.1970 по dt
function DateTimeToTimeStamp1970(dt:TDateTime):Longint;
begin
     result:=round((dt-strToDateTime('01.01.1970'))*24*3600);
end;

function GetSpecialFolderPath(folder : integer) : string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0,folder,0,SHGFP_TYPE_CURRENT,@path[0])) then
    Result := path
  else
    Result := '';
end;

{ **** UBPFD *********** by delphibase.endimus.com ****
>> Кодировка KOI8-R

Кодировка из Ansi в KOI8-R

Зависимости: нет
Автор:       Delirium, VideoDVD@hotmail.com, ICQ:118395746, Москва
Copyright:   Delirium (Master BRAIN) 2003
Дата:        17 октября 2003 г.
***************************************************** }

function ANSI2KOI8R(S: string): string;
var
  Ansi_CODE, KOI8_CODE: string;
  i: integer;
begin
  KOI8_CODE := 'бвчздецъйклмнопртуфхжигюыэящшьасБВЧЗДЕЦЪЙКЛМНОПРТУФХЖИГЮЫЭЯЩШЬАС—Ј';
  ANSI_CODE := 'АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя№ё';
  Result := S;
  for i := 1 to Length(Result) do
    if Pos(Result[i], ANSI_CODE) > 0 then
      Result[i] := KOI8_CODE[Pos(Result[i], ANSI_CODE)];
end;

function KOI8R2ANSI(s:string): string;
var
  Ansi_CODE, KOI8_CODE: string;
  i: integer;
begin
  KOI8_CODE := 'бвчздецъйклмнопртуфхжигюыэящшьасБВЧЗДЕЦЪЙКЛМНОПРТУФХЖИГЮЫЭЯЩШЬАС—Ј';
  ANSI_CODE := 'АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя№ё';
  Result := S;
  for i := 1 to Length(Result) do
    if Pos(Result[i], KOI8_CODE) > 0 then
      Result[i] := ANSI_CODE[Pos(Result[i], KOI8_CODE)];
end;


function FindLineSubstringInList( substring:string; List:TStrings ):integer; // Найти первый индекс строки списка, в которую входит подстрока. Возвращает номер строки списка или -1, если не найден
begin
for Result := 0 to List.Count - 1 do
    if pos(substring, List[result]) <> 0 then Exit;
  Result := -1;
end;

function GetNowStr():string;
begin
  result:=FormatDateTime('dd.mm.yyyy hh:nn:ss',Now());
end;

function isShiftName(shiftname:string):boolean;
var year,month,day:word;
    postfix:string;
    currentyear:word;
    yy,mm,dd:string;
    dt:TDate;
begin
     result:=true;
     if Length(shiftname)<>7 then result:=false;
     yy:=copy(shiftname,1,2);
     mm:=copy(shiftname,3,2);
     dd:=copy(shiftname,5,2);
     try
        dt:=StrToDate(dd+'.'+mm+'.'+yy);
     except
        result:=false;
     end;
     postfix:=copy(shiftname,7,1);
     if (postfix<>'d') and (postfix<>'n') then result:=false;
end;

function DateTimeToShiftName(dttm:TDateTime):string;
var dt,dt1:TDate;
    tm:TTime;
    prefix:string;
begin
     dt:=Trunc(date);
     tm:=dttm-dt;
     if tm>=StrToTime('19:30') then dt1:=dt+1 else dt1:=dt;
     if (tm>=StrToTime('7:30')) and (tm<StrToTime('19:30')) then prefix:='d' else prefix:='n';
     result:=FormatDateTime('yymmdd',dt1)+prefix;
end;

function ShiftNameToDateTime(shiftname:string):TDateTime;
var dd,mm,yy, postfix:string;
begin
     if isShiftName(shiftname) then begin
        yy:=copy(shiftname,1,2);
        mm:=copy(shiftname,3,2);
        dd:=copy(shiftname,5,2);
        postfix:=copy(shiftname,7,1);
        result:=StrToDate(dd+'.'+mm+'.'+yy);
        if postfix='d' then result:=result+StrToTime('7:30')
          else result:=result-StrToTime('4:30');
     end else result:=0;
end;

// Количество строк в текстовом файле
function LinesCount(const Filename: string): Integer;
var
  HFile: THandle;
  FSize, WasRead, i: Cardinal;
  Buf: array[1..4096] of byte;
begin
  Result := 0;
  HFile := CreateFile(Pchar(FileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if HFile <> INVALID_HANDLE_VALUE then
  begin
    FSize := GetFileSize(HFile, nil);
    if FSize > 0 then
    begin
      Inc(Result);
      ReadFile(HFile, Buf, 4096, WasRead, nil);
      repeat
        for i := WasRead downto 1 do
          if Buf[i] = 10 then
            Inc(Result);
        ReadFile(HFile, Buf, 4096, WasRead, nil);
      until WasRead = 0;
    end;
  end;
  CloseHandle(HFile);
end;

function GetModularStatusName(status:shortint):string;   // Получение названия статуса по номеру
begin
     case status of
      0: result:='неизвестно';
      1: Result:='Поломка';
      2: Result:='Готов';
      3: Result:='Ожидание';
      4: Result:='Задержка';
      else result:='';
     end;
end;

end.
