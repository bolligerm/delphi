unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  UnitA2;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FLastAlpha: TAlpha;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  UnitUser2;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  FLastAlpha := 'Hello';
//  Caption := IntToStr(DoubleUp(5));
  Caption := DoubleUp('Hello');
end;

end.
