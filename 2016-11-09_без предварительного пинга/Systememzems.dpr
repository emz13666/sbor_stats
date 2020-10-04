program Systememzems;

uses
  Forms,
  Main_systememzems in 'Main_systememzems.pas' {Form1System_emz_ems111111};


{$R *.res}
begin
  Application.Initialize;
  Application.CreateForm(TForm1System_emz_ems111111, Form1System_emz_ems111111);
  Application.ShowMainForm := false;
  Application.Run;
end.
