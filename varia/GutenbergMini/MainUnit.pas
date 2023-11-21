unit MainUnit;

// Printing from WebView2 with multiple copies

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Winapi.WebView2, Winapi.ActiveX,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Edge,
  WebView2Print;

type
  TForm1 = class(TForm)
    EdgeBrowser1: TEdgeBrowser;
    Panel1: TPanel;
    PrintButton: TButton;
    OpenButton: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    CopiesEdit: TEdit;
    procedure OpenButtonClick(Sender: TObject);
    procedure PrintButtonClick(Sender: TObject);
  private
    { Private declarations }
    procedure PrintingIsDone(errorCode: HResult; printStatus: TPrintStatus);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  System.TypInfo;

{$R *.dfm}

procedure TForm1.OpenButtonClick(Sender: TObject);
begin
  EdgeBrowser1.Navigate(Edit1.Text);
end;

procedure TForm1.PrintButtonClick(Sender: TObject);
var
  Copies: Integer;
begin
  Copies := StrToInt(CopiesEdit.Text);
  WebView2PrintCopies(EdgeBrowser1, Copies, PrintingIsDone);
end;

procedure TForm1.PrintingIsDone(ErrorCode: HResult; PrintStatus: TPrintStatus);
begin
  MessageDlg('Printing is done. Results: errorCode = ' + IntToStr(errorCode) + ', printStatus = ' +
    GetEnumName(TypeInfo(TPrintStatus), Ord(PrintStatus)),
    mtInformation, [mbOk], 0);
end;

end.
