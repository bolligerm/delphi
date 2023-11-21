program GutenbergMini;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {Form1},
  WebView2Print in 'WebView2Print.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
