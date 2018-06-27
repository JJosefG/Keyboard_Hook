unit Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  ShellAPI;

{$I Build.inc}
{$R bmpres.res}                                         //include the bitmap resources

type
  TfrmDetectKeys = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    TrayIconData: TNotifyIconData;
    { Private declarations }
  public
    { Public declarations }
  end;

const
  WM_ICONTRAY = WM_USER + 1;
var
  frmDetectKeys: TfrmDetectKeys;

implementation

{$R *.dfm}

//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.FormCreate(Sender: TObject);
begin
  with TrayIconData do begin
    cbSize  := System.SizeOf(TrayIconData);
    Wnd     := Handle;
    uID     := 0;
    uFlags  := NIF_MESSAGE + NIF_ICON + NIF_TIP;
    uCallbackMessage := WM_ICONTRAY;
    hIcon := Application.Icon.Handle;
    StrPCopy(szTip, Application.Title);
  end;
  Shell_NotifyIcon(NIM_ADD, @TrayIconData);
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.FormDestroy(Sender: TObject);
begin
  Shell_NotifyIcon(NIM_DELETE, @TrayIconData);
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if GetKeyState(VK_NUMLOCK) < 0 then begin

  end
  else begin

  end;
end;
//---------------------------------------------------------------------------------------------------------------------
end.
