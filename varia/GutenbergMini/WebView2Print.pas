unit WebView2Print;

// This code by Matthias Bolliger is inspired by
// https://github.com/MicrosoftDocs/edge-developer/blob/main/microsoft-edge/webview2/how-to/print.md

interface

uses
  System.SysUtils,
  // Unit Winapi.WebView2 must come after WebView2_TLB in the uses list,
  // because any types defined in both those units (any overlap)
  // must lead to the type from Winapi.WebView2 being used,
  // because that's what TCustomEdgeBrowser uses
  WebView2_TLB,
  Winapi.WebView2,
  Vcl.Edge;

type
  TPrintStatus = (psSucceeded, psPrinterUnavailable, psOtherError, psUnknown);
  TCallWhenDonePrinting = procedure(ErrorCode: HResult; PrintStatus: TPrintStatus) of object;

procedure WebView2PrintCopies(EdgeBrowser: TCustomEdgeBrowser;
  Copies: Integer; CallWhenDone: TCallWhenDonePrinting);


implementation

uses
  Winapi.ActiveX;

type
  TCompletedHandler = class(TInterfacedObject, ICoreWebView2PrintCompletedHandler)
  private
    function Invoke(errorCode: HResult; printStatus: COREWEBVIEW2_PRINT_STATUS): HResult; stdcall;
  end;

threadvar
  CallWhenDonePrinting: TCallWhenDonePrinting;

procedure WebView2PrintCopies(EdgeBrowser: TCustomEdgeBrowser;
  Copies: Integer; CallWhenDone: TCallWhenDonePrinting);
var
  Core2: ICoreWebView2;
  Core2_16: ICoreWebView2_16;
  Environment: ICoreWebView2Environment;
  Environment6: ICoreWebView2Environment6;
  PrintSettings: ICoreWebView2PrintSettings;
  PrintSettings2: ICoreWebView2PrintSettings2;
  HR: HRESULT;
  CompletedHandler: ICoreWebView2PrintCompletedHandler;
begin
  // Remember the callback to call when we're done
  CallWhenDonePrinting := CallWhenDone;

  // Check that the currently installed version of WebView2
  // supports core interface version 16 (which has the Print support we need)
  EdgeBrowser.ControllerInterface.Get_CoreWebView2(Core2);
  if not Assigned(Core2) then
    raise Exception.Create('Get_CoreWebView2 not found');

  Core2.QueryInterface(IID_ICoreWebView2_16, Core2_16);
  if not Assigned(Core2_16) then
    raise Exception.Create('IID_ICoreWebView2_16 not found - necessary Print support lacking');

  // Check that the currently installed version of WebView2
  // supports environment interface version 6 (which has CreatePrintSettings)
  Environment := EdgeBrowser.EnvironmentInterface;

  Environment.QueryInterface(IID_ICoreWebView2Environment6, Environment6);
  if not Assigned(Environment6) then
    raise Exception.Create('IID_ICoreWebView2Environment6 not found - necessary CreatePrintSettings support lacking');

  // Create print settings
  Environment6.CreatePrintSettings(PrintSettings);
  if not Assigned(PrintSettings) then
    raise Exception.Create('PrintSettings not found');

  // Check that the currently installed version of WebView2
  // supports print settings interface version 2 (which has the Copies property, among other things)
  PrintSettings.QueryInterface(IID_ICoreWebView2PrintSettings2, PrintSettings2);
  if not Assigned(PrintSettings2) then
    raise Exception.Create('IID_ICoreWebView2PrintSettings2 not found - necessary Copies support lacking');

  //
  // Now everything that we need seems to be in place - go on with actual printing
  //

  // Set the wanted number of copies (could also set other settings here)
  PrintSettings2.Set_Copies(Copies);

  // Since this variable is of interface type, the object will get auto-Freed
  CompletedHandler := TCompletedHandler.Create;

  HR := Core2_16.Print(PrintSettings2, CompletedHandler);
  if not Succeeded(HR) then
    raise Exception.Create('ICoreWebView2_16.Print failed');
end;

{ TCompletedHandler }

function TCompletedHandler.Invoke(errorCode: HResult;
  printStatus: COREWEBVIEW2_PRINT_STATUS): HResult;
var
  ResultStatus: TPrintStatus;
begin
  case printStatus of
    COREWEBVIEW2_PRINT_STATUS_SUCCEEDED:  ResultStatus := psSucceeded;
    COREWEBVIEW2_PRINT_STATUS_PRINTER_UNAVAILABLE:  ResultStatus := psPrinterUnavailable;
    COREWEBVIEW2_PRINT_STATUS_OTHER_ERROR:  ResultStatus := psOtherError;
  else
    ResultStatus := psUnknown;
  end;

  CallWhenDonePrinting(errorCode, ResultStatus);
end;

end.
