unit Previnst;

interface

uses Windows;

var
  mmm: boolean; //эта переменная если true то программа уже запущена

implementation

var
  hMutex: integer;
begin
  mmm := false;
  hMutex := CreateMutex(nil, TRUE, '08965AbraShvabraEMZUbiquitYY'); // Создаем семафор
  if GetLastError <> 0 then
    mmm := true; // Ошибка семафор уже создан
  ReleaseMutex(hMutex);
end.


