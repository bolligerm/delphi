program RenameRefactoringTest;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {Form1},
  UnitA1 in 'UnitA1.pas',
  UnitA2 in 'UnitA2.pas',
  UnitUser1 in 'UnitUser1.pas',
  UnitUser2 in 'UnitUser2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
