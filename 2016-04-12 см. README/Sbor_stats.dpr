program Sbor_stats;

uses
 // UnitTestMemoryLeak,
  //FastMM4,
  Forms,
  previnst,
  windows,
  MainUnit in 'MainUnit.pas' {Form1};

{$R *.res}

begin

 if mmm then
  begin
//      MessageBox(Application.Handle,PChar('Одна копия программы уже запущена!'),PChar('Ошибка'),MB_OK);
      halt; //завершить программу не создавая ничего.
  end;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  ShowWindow(Application.Handle,SW_HIDE);
  Application.Run;

end.
