unit MyDB;

interface

uses
  SysUtils,  Classes,  Controls, StdCtrls, Forms,
  Dialogs, DBLocalS, Registry, Graphics, DateUtils, Variants, DBTables,
  Windows, SqlExpr, DB, DBGrids, RxDBCtrl, ComObj, ActiveX, NB30, TTDBGrid,
  WinSock;

type
  TMyStack= class (TObject)
  private
    FMyStack: array of integer;
    FMyStackStr: array of string;
  public
    procedure push_stack(FValue: integer; FValStr: string);
    procedure pop_stack(var FInt: integer; var FStr: string);
    constructor create;
    destructor destroy;override;
  end;
procedure AddToListFromDB(Query: TSQLQuery; List: TStrings; Pole, Table: string);
procedure AddFilesToTable(TblFilesName:string;Fields, Values: array of string);
procedure AddToTable(Table: string; Fields, Values: array of string);
procedure AddToStats_operTable(Operation: string);
procedure UpdateToTable(Table, KeyField, KeyValue: string; Fields, Values: array of string);
procedure UpdateToFilesTable(TblFilesName, KeyField, KeyValue: string; Fields, Values: array of string);
function DeleteFromTable(Table, KeyField, ValueKeyField: string; ShowConf: boolean): boolean;
function DeleteFromTableWhere(Table, FWhere: string): boolean;
function CountRecordInMySQLTable(Query: TSQLQuery; Pole, Znach, Base: String): longint;
function FindIndex(Value: Integer; ArrInt: array of integer): Integer;
function StrToHex(Value: string): String;
function Crpt(value: string): string;
function ifNullFile(id,KeyName, TableFilesName: string): boolean;
function ifNullFileAkt(id,KeyName, TableFilesName: string): boolean;
function ifNullFileMeropr(id,KeyName, TableFilesName: string): boolean;
function isNullField(Table,Field,id,Value_id: string): boolean;
function MaxValue(Table, Field: string): Integer;
function Null_Query(var Query: TSQLQuery; TableName, Uslovie: string): boolean;
function GetMACAddress: string;
function GetLocalIP: String;
function date_server: TDateTime;
function MyUpperCase(Value: char): Char;
procedure ExportToExcel(Var Grid: TRxDBGrid);
procedure Export_To_Excel(Var Grid: TToolTipsDBGrid);
function IsOLEObjectInstalled(Name: String): boolean;

var
  Add_Edit: boolean = true; //текущий режим - добавления (true) или редактирования записей

implementation

uses  UnitDM, UnitTable, UnitMain;

function MyUpperCase(Value: char): Char;
var s:string;
begin
  s := '';
  s := s + Value;
  s := AnsiUpperCase(s);
  Result := s[1];
end;

function GetLocalIP: String;
const WSVer = $101;
var
  wsaData: TWSAData;
  P: PHostEnt;
  Buf: array [0..127] of Char;
begin
  Result := '';
  if WSAStartup(WSVer, wsaData) = 0 then begin
    if GetHostName(@Buf, 128) = 0 then begin
      P := GetHostByName(@Buf);
      if P <> nil then Result := iNet_ntoa(PInAddr(p^.h_addr_list^)^);
    end;
    WSACleanup;
  end;
end;

function GetAdapterInfo(Lana: Char): string;
var
  Adapter: TAdapterStatus;
  NCB: TNCB;
begin
  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := Char(NCBRESET);
  NCB.ncb_lana_num := Lana;
  if Netbios(@NCB) <> Char(NRC_GOODRET) then
  begin
    Result := 'mac not found';
    Exit;
  end;

  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := Char(NCBASTAT);
  NCB.ncb_lana_num := Lana;
  NCB.ncb_callname := '*';

  FillChar(Adapter, SizeOf(Adapter), 0);
  NCB.ncb_buffer := @Adapter;
  NCB.ncb_length := SizeOf(Adapter);
  if Netbios(@NCB) <> Char(NRC_GOODRET) then
  begin
    Result := 'mac not found';
    Exit;
  end;
  Result :=
  IntToHex(Byte(Adapter.adapter_address[0]), 2) + '-' +
  IntToHex(Byte(Adapter.adapter_address[1]), 2) + '-' +
  IntToHex(Byte(Adapter.adapter_address[2]), 2) + '-' +
  IntToHex(Byte(Adapter.adapter_address[3]), 2) + '-' +
  IntToHex(Byte(Adapter.adapter_address[4]), 2) + '-' +
  IntToHex(Byte(Adapter.adapter_address[5]), 2);
end;

function GetMACAddress: string;
var
  AdapterList: TLanaEnum;
  NCB: TNCB;
begin
  FillChar(NCB, SizeOf(NCB), 0);
  NCB.ncb_command := Char(NCBENUM);
  NCB.ncb_buffer := @AdapterList;
  NCB.ncb_length := SizeOf(AdapterList);
  Netbios(@NCB);
  if Byte(AdapterList.length) > 0 then
    Result := GetAdapterInfo(AdapterList.lana[0])
  else
    Result := 'mac not found';
end;

//добавляет запись в таблицу статистики операций
procedure AddToStats_operTable(Operation: string);
var q: string;
begin
  Operation := StringReplace(Operation,'''','"',[rfReplaceAll]);
  q := 'Insert into stat_operation(Date_time,Login,IP,mac_address,operation)' +
  ' values ('''+FormatDateTime('yyyy-mm-dd hh:mm:ss',now)+''','''+user_name+''','''+
  GetLocalIP+''','''+GetMACAddress+''','''+Operation+''')';

  with DM.Query do
  begin
    try
      Close;
      SQL.Text := q;
      Prepared := true;
      ExecSQL;
      close;
    except
      //MessageDlg('Ошибка обращения к базе данных (AddToStats_operTable)',mtError,[mbOK],0);
    end;
  end;
end;

//процедура добавляет в список List все значения поля Pole из таблицы Table
procedure AddToListFromDB(Query: TSQLQuery;List: TStrings; Pole, Table: string);
begin
  Query.Close;
  Query.SQL.Text := 'select distinct ' + Pole + ' from ' + Table + ' order by ' + Pole;
 try
  Query.Open;
  Query.First;
  while not Query.Eof do
  begin
    if (Query.FieldByName(Pole).AsString) <> '' then
      List.Add(query.FieldByName(Pole).AsString);
    Query.Next;
  end;
 except
//  MessageDlg('Ошибка обращения к базе данных',mtError,[mbOK],0);
 end;
 Query.Close;
end;

//функция возвращает количество связанных с полем Pole записей в таблице Base
function CountRecordinMySQLTable(Query: TSQLQuery; Pole, Znach, Base: String): longint;
begin
  Result := 0;
  Query.Close;
  if Znach='' then znach:='-1';
  if UpperCase(base)<>'FILES' then
    Query.SQL.Text := 'select count(*) as kol_vo from ' + Base + ' where ' + Pole + '=' + '"' +
   Znach+ '"'
  else
    Query.SQL.Text := 'select count(id_files) as kol_vo from ' + Base + ' where ' + Pole + '=' + '"' +
   Znach+ '"';
  try
    Query.Open;
    Query.FindLast;
    Result := Query.Fields.Fields[0].AsInteger;
  except
//    MessageDlg('Ошибка обращения к базе данных',mtError,[mbOK],0);
  end;
  Query.Close;
end;

//возвращает индекс элемента массива, ззначение которого = value
function FindIndex(Value: Integer; ArrInt: array of integer): Integer;
begin
  Result := 0;
  while (Result <= high(ArrInt)) and (Value <> ArrInt[Result]) do inc(Result);
  if Value <> arrint[Result] then Result := -1;
end;

function StrToHex(Value: string): String;
var
  c: char;
  b: byte;
  i: Longword;
begin
  Result := '';
  for i := 1 to length(Value) do
  begin
    c := Value[i];
    asm
      mov al, c
      mov b, al
    end;
    Result := Result + IntToHex(b,2);
  end;
end;


//процедура добавления записи в таблицу
procedure AddToTable(Table: string; Fields, Values: array of string);
var
  i: integer;
  q: string;
begin
  if Length(Fields) <> Length (Values) then
  begin
    ShowMessage('Length(Fields) <> Length (Values)');
    exit;
  end;
  q := 'Insert into ' + Table + '(';
  for i := 0 to High(Fields)-1 do
  begin
    q := q + Fields[i] + ',';
  end;
  q := q + Fields[high(Fields)] + ') values(';
  for i := 0 to high(values)-1 do
  begin
   if Fields[i] = 'passwd' then q := q + 'PASSWORD(''' + values[i] + '''),'
   else
     if Values[i]='' then q := q + 'NULL,'
     else  q := q + '''' + StringReplace(values[i],'''','"',[rfReplaceAll]) + ''',';
  end;

  if Fields[High(fields)] = 'passwd' then q := q + 'PASSWORD(''' + Values[high(Values)] + '''))'
  else
    if Values[high(Values)]='' then q := q + 'NULL)'
    else  q := q + '''' + Values[high(Values)] + ''')';
  Table := UpperCase(Table);
  if (table<>'KNIGA_OTZIVOV')and(Table<>'STATS')and(Table<>'PEOPLE')and(Copy(Table,1,3)<>'SL_') then AddToStats_operTable(q);

  with DM.Query do
  begin
    try
      Close;
      SQL.Text := q;
      Prepared := true;
      ExecSQL;
      close;
//      if UpperCase(Table)<>'STATISTICS' then AddToStats_operTable(['login','operation','time_execute'],[user_name, q, FormatDateTime('yyyy-mm-dd hh-nn-ss',Now)]);
    except
      MessageDlg('Ошибка обращения к базе данных',mtError,[mbOK],0);
    end;
  end;
end;

procedure AddFilesToTable(TblFilesName:string;Fields, Values: array of string);
var
  i: integer;
  q, q1, table: string;

begin
  table := TblFilesName;
  if Length(Fields) <> Length (Values) then
  begin
    ShowMessage('Length(Fields) <> Length (Values)');
    exit;
  end;
  q := 'Insert into ' + Table + '(';
  for i := 0 to High(Fields)-1 do
  begin
    q := q + Fields[i] + ',';
  end;
  q := q + Fields[high(Fields)] + ') values(';
  q1 := q;
  for i := 0 to high(values)-1 do
  begin
   if Values[i]='' then begin q := q + 'NULL,';q1 := q1 + 'NULL,'; end
   else
     if Fields[i] = 'data' then begin q := q + values[i] + ','; q1 := q1 + 'BINARY_DATA,' end
     else
       begin q := q + '''' + values[i] + ''','; q1 := q1 + '''' + values[i] + ''','; end;
  end;

  if Values[high(Values)]='' then begin  q := q + 'NULL)'; q1 := q1 + 'NULL)' end
  else
    if Fields[high(Fields)] = 'data' then begin q := q + values[high(values)] + ')'; q1 := q1 + 'BYNARY_DATA)'; end
    else
     begin q := q + '''' + Values[high(Values)] + ''')'; q1 := q1 + '''' + Values[high(Values)] + ''')'; end;
  with DM.Query do
  begin
    try
      Close;
      SQL.Text := q;
      Prepared := true;
      ExecSQL;
      close;

    except
//      MessageDlg('Ошибка обращения к базе данных',mtError,[mbOK],0);
    end;
  end;
end;

//процедура изменения записи
procedure UpdateToTable(Table, KeyField, KeyValue: string; Fields, Values: array of string);
var
  i: integer;
  query: string;
begin
  query := 'Update ' + Table + ' set ';

  for i := 0 to high(Fields)-1 do
   if Fields[i] = 'passwd' then
     query := query + fields[i] + '=' + 'PASSWORD(''' + values[i] + '''),'
   else
     if Values[i] = '' then query := query + fields[i] + '=NULL,'
     else  query := query + fields[i] + '=' + '''' + StringReplace(values[i],'''','"',[rfReplaceAll]) + ''',';

   if Fields[high(fields)] = 'passwd' then
     query := query + fields[high(fields)] + '=' + 'PASSWORD(''' + values[high(values)] + ''')'
   else
      if Values[High(Values)] = '' then query := query + fields[High(Fields)] + '=NULL'
      else  query := query + fields[High(Fields)] + '=' + '''' + StringReplace(values[High(Fields)],'''','"',[rfReplaceAll]) + '''';

  query := query + ' where ' + KeyField + '=''' + KeyValue + '''';

  Table := UpperCase(Table);
  if (table<>'KNIGA_OTZIVOV')and(Table<>'STATS')and(Table<>'PEOPLE')and(Copy(Table,1,3)<>'SL_') then AddToStats_operTable(query);

  with DM.Query do
    try
      Close;
      SQL.Text := query;
      Prepared := true;
      ExecSQL;
      close;
//      if UpperCase(Table)<>'SEQUR' then AddToStats_operTable(['login','operation','time_execute'],[user_name, query, FormatDateTime('yyyy-mm-dd hh-nn-ss',Now)]);
    except
//      MessageDlg('Ошибка обращения к базе данных',mtError,[mbOK],0);
    end;
end;

procedure UpdateToFilesTable(TblFilesName, KeyField, KeyValue: string; Fields, Values: array of string);
var
  i: integer;
  query, query_1, Table: string;
begin
  Table :=TblFilesName;
  query := 'Update ' + Table + ' set ';
  query_1 := query;
  for i := 0 to high(Fields)-1 do
     if Values[i] = '' then begin  query := query + fields[i] + '=NULL,'; query_1 := query_1 + fields[i] + '=NULL,' end
     else
       if Fields[i] = 'data' then begin query := query + fields[i] + '=' + values[i] + ','; query_1 := query_1 + fields[i] + '=BYNARY_DATA,'; end
       else begin query := query + fields[i] + '=' + '''' + values[i] + ''','; query_1 := query_1 + fields[i] + '=' + '''' + values[i] + ''','; end;

  if Values[High(Values)] = '' then begin query := query + fields[High(Fields)] + '=NULL'; query_1 := query_1 + fields[High(Fields)] + '=NULL' end
  else
       if Fields[High(Fields)] = 'data' then begin query := query + fields[High(Fields)] + '=' + values[High(Fields)]; query_1 := query_1 + fields[High(Fields)] + '=BYNARY_DATA'; end
       else begin query := query + fields[High(Fields)] + '=' + '''' + values[High(Fields)] + ''''; query_1 := query_1 + fields[High(Fields)] + '=' + '''' + values[High(Fields)] + ''''; end;

  query := query + ' where ' + KeyField + '=''' + KeyValue + '''';
  query_1 := query_1 + ' where ' + KeyField + '=''' + KeyValue + '''';

  with DM.Query do
    try
      Close;
      SQL.Text := query;
      Prepared := true;
      ExecSQL;
      close;
//      AddToStats_operTable(['login','operation','time_execute'],[user_name, query_1, FormatDateTime('yyyy-mm-dd hh-nn-ss',Now)]);
    except
//      MessageDlg('Ошибка обращения к базе данных',mtError,[mbOK],0);
    end;
end;

function DeleteFromTable(Table, KeyField, ValueKeyField: string; ShowConf: boolean): boolean;
var query1: string;
begin
  //удаление выбранной записи
  Result := false;
  if ShowConf then
  begin
    if MessageDlg('Точно удалить запись "' + ValueKeyField + '" ?', mtConfirmation,[mbYes,mbNo],0)=mrYes then
    begin
        try
          DM.Query.Close;
          DM.Query.SQL.Text := 'Delete from ' + Table + ' where ' +
            KeyField + '=' + ValueKeyField;
          query1 := DM.Query.SQL.Text;
          DM.Query.Prepared := true;
          DM.Query.ExecSQL;
          Result := true;
          DM.Query.Close;
          Table := UpperCase(Table);
          if (table<>'KNIGA_OTZIVOV')and(Table<>'STATS')and(Table<>'PEOPLE')and(Copy(Table,1,3)<>'SL_') then AddToStats_operTable(query1);
        except
          MessageDlg('Ошибка удаления записи',mtError,[mbOK],0);
        end
    end
  end
  else
  begin
      try
        DM.Query.Close;
        DM.Query.SQL.Text := 'Delete from ' + Table + ' where ' +
          KeyField + '=' + ValueKeyField;
        query1 := DM.Query.SQL.Text;
        DM.Query.Prepared := true;
        DM.Query.ExecSQL;
        Result := true;
        DM.Query.Close;
        Table := UpperCase(Table);
        if (table<>'KNIGA_OTZIVOV')and(Table<>'STATS')and(Table<>'PEOPLE')and(Copy(Table,1,3)<>'SL_') then AddToStats_operTable(query1);
      except
        MessageDlg('Ошибка удаления записи',mtError,[mbOK],0);
      end
  end;
end;

function DeleteFromTableWhere(Table, FWhere: string): boolean;
var query1: string;
begin
  Result := false;
  try
        DM.Query.Close;
        DM.Query.SQL.Text := 'Delete from ' + Table + ' where ' + FWhere;
        query1 := DM.Query.SQL.Text;
        DM.Query.Prepared := true;
        DM.Query.ExecSQL;
        Result := true;
        DM.Query.Close;
  except
    Result := false;
    DM.Query.Close;
  end;
end;

function ifNullFileMeropr(id,KeyName, TableFilesName: string): boolean;
begin
  Result := True;
    with DM.Query do
    begin
      Close;
      SQL.Text := 'SELECT count_part from '+ TableFilesName + ' WHERE ' + KeyName+'='+id+
        ' and id_razdel=0';
      Open;
      First;
      if FieldByName('count_part').AsString <> '0' then Result := False;
      Close;
    end;
end;

function ifNullFileAkt(id,KeyName, TableFilesName: string): boolean;
begin
  Result := True;
    with DM.Query do
    begin
      Close;
      SQL.Text := 'SELECT count_part from '+ TableFilesName + ' WHERE ' + KeyName+'='+id+
       ' and id_razdel=1';
      Open;
      First;
      if recordcount>0 then
        if FieldByName('count_part').AsString <> '0' then Result := False;
      Close;
    end;
end;

function ifNullFile(id,KeyName, TableFilesName: string): boolean;
begin
  Result := True;
  if CountRecordInMySQLTable(DM.Query,keyname,id,TableFilesName)>0 then
  begin
    with DM.Query do
    begin
      Close;
      SQL.Text := 'SELECT count_part from '+ TableFilesName + ' WHERE ' + KeyName+'='+id;
      Open;
      First;
      if FieldByName('count_part').AsString <> '0' then Result := False;
      Close;
    end;
  end;
end;

function MaxValue(Table, Field: string): Integer;
begin
  with DM.Query do
  begin
    Close;
    SQL.Text := 'SELECT MAX(' + Field + ') as maxvalue FROM ' + Table;
    Open;
    First;
    Result := FieldByName('maxvalue').AsInteger;
    Close;
  end;
end;

function isNullField(Table,Field,id,Value_id: string): boolean;
begin
  Result := false;
  begin
    with DM.Query do
    begin
      Close;
      SQL.Text := 'SELECT * from ' + Table + ' WHERE ' + id+'='+Value_id +' and ';
      Open;
      First;
      if FieldByName('data').AsString <> '' then Result := False;
      Close;
    end;
  end;
end;

function Null_Query(var Query: TSQLQuery; TableName, Uslovie: string): boolean;
begin
  Query.Close;
  Query.SQL.Text := 'SELECT * FROM ' + TableName + ' WHERE ' + Uslovie;
  Query.Open;
  Result := Query.IsEmpty;
  Query.Close;
end;

function WhichLanguage:string;
var
  ID: LangID;
  Language: array [0..100] of char;
begin
  ID := GetSystemDefaultLangID;
  VerLanguageName(ID, Language, 100);
  Result := string(Language);
end;

function IsOLEObjectInstalled(Name: String): boolean;
var
  ClassID: TCLSID;
  Rez : HRESULT;
begin
  // Ищем CLSID OLE-объекта
  Rez := CLSIDFromProgID(PWideChar(WideString(Name)), ClassID);
  if Rez = S_OK then  // Объект найден
    Result := true
  else
    Result := false;
end;

function Crpt(value: string): string;
var i: Longword;
begin
  Result := '';
  for i:=1 to length(value) do
    Result := Result + chr(ord(value[i]) xor 13);
end;

function date_server: TDateTime;
var s1,s2: string;
begin
  with dm.Query_date do
  begin
    Close;
    SQL.Text := 'SELECT NOW() from siz limit 1';
    Open;
    s1 := Fields[0].AsString;
    Close;
    s2:=copy(s1,9,2)+'.'+copy(s1,6,2)+'.'+copy(s1,1,4);
    Result := StrToDate(s2);
  end;
end;

{ TMyStack }

constructor TMyStack.create;
begin
  SetLength(FMyStack,0);
  SetLength(FMyStack,0);
end;

destructor TMyStack.destroy;
begin
  SetLength(FMyStack,0);
  SetLength(FMyStackStr,0);
  inherited destroy;
end;

procedure TMyStack.pop_stack(var FInt: integer; var FStr: string);
begin
  if  Length(FmyStack)= 0 then FInt := -1 //если стэк пуст, то -1
  else
  begin
    FInt := FMyStack[High(FMyStack)];
    SetLength(FMyStack, High(FMyStack));
    FStr := FMyStackStr[High(FMyStackStr)];
    SetLength(FMyStackStr, High(FMyStackStr));
  end;
end;

procedure TMyStack.push_stack(FValue: integer; FValStr: string);
begin
  SetLength(FMyStack,Length(FMyStack)+1);
  SetLength(FMyStackStr,Length(FMyStackStr)+1);
  FMyStack[High(FMyStack)] := FValue;
  FMyStackStr[High(FMyStackStr)] := FValStr;
end;

procedure ExportToExcel(Var Grid: TRxDBGrid);
var
  ExcelApp, WorkBook: Variant;
var
  bm: TBookmark;
  col, row: Integer;
  sline: string;
  mem: TMemo;
  Layout: array[0.. KL_NAMELENGTH] of char;
begin
//установлен ли EXCEL
  if not IsOLEObjectInstalled('Excel.Application') then
  begin
    ShowMessage('Экспорт невозможен. Excel не установлен.');
    exit;
  end;

 // Создание Excel
      ExcelApp := CreateOleObject('Excel.Application');


  WorkBook := ExcelApp.WorkBooks.Add;
  Screen.Cursor := crHourglass;
  Grid.DataSource.DataSet.DisableControls;
  bm := Grid.DataSource.DataSet.GetBookmark;
  Grid.DataSource.DataSet.First;

  // Сперва отправляем данные в memo
  // работает быстрее, чем отправлять их напрямую в Excel
  mem := TMemo.Create(frmTable);
  mem.Parent := frmTable;
  mem.Visible := false;
  mem.Clear;
  sline := '';

  // добавляем информацию для имён колонок
  for col := 0 to Grid.Columns.Count-1 do
    sline := sline + Grid.Columns[col].Title.Caption + #9;
  mem.Lines.Add(sline);

  // получаем данные из DBGrid
  for row := 0 to Grid.DataSource.DataSet.RecordCount-1 do
  begin
    sline := '';
    for col := 0 to Grid.Columns.Count-1 do
      if Grid.Columns[col].Field.AsString='30.12.1899' then
        sline := sline + #9
      else
        sline := sline + Grid.Columns[col].Field.AsString + #9;
    mem.Lines.Add(sline);
    Grid.DataSource.DataSet.Next;
  end;

  // копируем данные в clipboard
  mem.SelectAll;
  // переключаем раскладку на русский
  LoadKeyboardLayout( StrCopy(Layout,'00000419'),KLF_ACTIVATE);
  mem.CopyToClipboard;
  mem.Free;


  // отправляем их в Excel

  Workbook.WorkSheets[1].Paste;
  Workbook.WorkSheets[1].Range['A1','AA1'].Font.Size := 11;
  Workbook.WorkSheets[1].Range['A1','AA1'].Font.Bold := true;
  Workbook.WorkSheets[1].Columns.AutoFit;
  Workbook.WorkSheets[1].Range['A1',EmptyParam].Select;

  ExcelApp.Visible := true;

  Grid.DataSource.DataSet.GotoBookmark(bm);
  Grid.DataSource.DataSet.FreeBookmark(bm);
  Grid.DataSource.DataSet.EnableControls;
  Screen.Cursor := crDefault;

end;

procedure Export_To_Excel(Var Grid: TToolTipsDBGrid);
var
  ExcelApp, WorkBook: Variant;
var
  bm: TBookmark;
  col, row: Integer;
  sline: string;
  mem: TMemo;
  Layout: array[0.. KL_NAMELENGTH] of char;
begin
//установлен ли EXCEL
  if not IsOLEObjectInstalled('Excel.Application') then
  begin
    ShowMessage('Экспорт невозможен. Excel не установлен.');
    exit;
  end;

 // Создание Excel
      ExcelApp := CreateOleObject('Excel.Application');


  WorkBook := ExcelApp.WorkBooks.Add;
  Screen.Cursor := crHourglass;
  Grid.DataSource.DataSet.DisableControls;
  bm := Grid.DataSource.DataSet.GetBookmark;
  Grid.DataSource.DataSet.First;

  // Сперва отправляем данные в memo
  // работает быстрее, чем отправлять их напрямую в Excel
  mem := TMemo.Create(frmMain);
  mem.Parent := frmMain;
  mem.Visible := false;
  mem.Clear;
  sline := '';

  // добавляем информацию для имён колонок
  for col := 0 to Grid.Columns.Count-1 do
    sline := sline + Grid.Columns[col].Title.Caption + #9;
  mem.Lines.Add(sline);

  // получаем данные из DBGrid
  for row := 0 to Grid.DataSource.DataSet.RecordCount-1 do
  begin
    sline := '';
    for col := 0 to Grid.Columns.Count-1 do
      if Grid.Columns[col].Field.AsString='30.12.1899' then
        sline := sline + #9
      else
        sline := sline + Grid.Columns[col].Field.AsString + #9;
    mem.Lines.Add(sline);
    Grid.DataSource.DataSet.Next;
  end;

  // копируем данные в clipboard
  mem.SelectAll;
  // переключаем раскладку на русский
  LoadKeyboardLayout( StrCopy(Layout,'00000419'),KLF_ACTIVATE);
  mem.CopyToClipboard;
  mem.Free;


  // отправляем их в Excel

  Workbook.WorkSheets[1].Paste;
  Workbook.WorkSheets[1].Range['A1','AA1'].Font.Size := 11;
  Workbook.WorkSheets[1].Range['A1','AA1'].Font.Bold := true;
  Workbook.WorkSheets[1].Columns.AutoFit;
  Workbook.WorkSheets[1].Range['A1',EmptyParam].Select;

  ExcelApp.Visible := true;

  Grid.DataSource.DataSet.GotoBookmark(bm);
  Grid.DataSource.DataSet.FreeBookmark(bm);
  Grid.DataSource.DataSet.EnableControls;
  Screen.Cursor := crDefault;

end;

end.
