object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Gutenberg Mini'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Constraints.MinHeight = 200
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object EdgeBrowser1: TEdgeBrowser
    Left = 0
    Top = 41
    Width = 624
    Height = 400
    Align = alClient
    TabOrder = 0
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
    ExplicitTop = 39
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 41
    Align = alTop
    TabOrder = 1
    DesignSize = (
      624
      41)
    object Label1: TLabel
      Left = 452
      Top = 13
      Width = 39
      Height = 15
      Anchors = [akTop, akRight]
      Caption = '&Copies:'
      FocusControl = CopiesEdit
    end
    object PrintButton: TButton
      Left = 540
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Print'
      TabOrder = 3
      OnClick = PrintButtonClick
    end
    object OpenButton: TButton
      Left = 351
      Top = 8
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Open'
      TabOrder = 1
      OnClick = OpenButtonClick
    end
    object Edit1: TEdit
      Left = 12
      Top = 8
      Width = 333
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = 'http://www.bolliger.se'
    end
    object CopiesEdit: TEdit
      Left = 502
      Top = 9
      Width = 30
      Height = 23
      Anchors = [akTop, akRight]
      TabOrder = 2
      Text = '1'
    end
  end
end
