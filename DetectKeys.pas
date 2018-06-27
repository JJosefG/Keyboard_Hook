//---------------------------------------------------------------------------------------------------------------------
// Learning how to
// 1. Put the application into the Notification Bar
// 2. Using keyboard hook to notify the non-windowed application of key state changes (commented out in this version)
// 3. Update the notification icon depending on keyboard events
// We've learned
// 1. Only the window that has focus receives Windows Messages during normal user interaction.
// 2. It is possible to have non-windowed apps rececive user input via AllocateHWND() but here we are not using this method
// 3. It is possible to globally intercept all windows messages (here we just do the keyboard events)
// 4. A simple timer that checks the keybaord state in regular intervals works most reliably.
//---------------------------------------------------------------------------------------------------------------------
unit DetectKeys;

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
  ShellAPI,
  Vcl.Menus,
  Vcl.ExtCtrls,
  SHFolder,
  myProcs,
  System.IOUtils,
  Logging,
  iniFiles,
  Options;


{$I Build.inc}                                     //include build file
{$R bmpres.res}                                    //include the bitmap resources

const
  WM_ICONTRAY     = WM_USER + 1;
  WM_UpdateIcon   = WM_USER + 2;
  Toggled_ON  = 1;
  Toggled_Off = 0;

  strlNumLock_ON      = 'NumLock now ON';
  strlNumLock_Off     = 'NumLock now OFF';
  strlDirCreateErr    = 'Error creating directory: ';
  strlLogFilesDir     = 'Log_Files\';
  strlOptionsCaption  = Concat(strAppTitle,' - Options');

  strlHeader                = 'Information';
  strlProgInfo              = 'Program Data';
  strlProgramInformation    = Concat(strAppTitle,' - Program Settings File - (c) 2018 Atlantic Zeiser, Inc.');
  strlSettings              = 'Settings';
  strlLogLevel              = 'Log_Level(0: Cap/NumLock,1: All Keys)';

//----keyboard hook
type
  pKBDLLHOOKSTRUCT = ^KBDLLHOOKSTRUCT;

  KBDLLHOOKSTRUCT = packed record
    vkCode      : DWORD;
    scanCodem   : DWORD;
    flags       : DWORD;
    time        : DWORD;
    dwExtraInfo : ULONG_PTR;
  end;
//----------------------------
type
  TLog_Level = (ll_AllKeys, ll_CapsNumlock);

type
  TfrmDetectKeys = class(TForm)
    pmnu: TPopupMenu;
    mnuOptions: TMenuItem;
    N1: TMenuItem;
    mnuExit: TMenuItem;
    tmr_1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Load_Icon(Sender: TObject; const IconName: String);
    procedure Show_In_Tray(Sender: TObject;const isNew: boolean; const iconName: String);
    procedure IconResponse(var Msg: TMessage); message WM_ICONTRAY;
    procedure Key_Up_Detected(var Msg: TMessage); message WM_UpdateIcon;
    procedure mnuExitClick(Sender: TObject);
    procedure Check_Key(Sender: TObject);
    procedure Init_Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mnuOptionsClick(Sender: TObject);
  protected

  private
    TrayIconData: TNotifyIconData;
    procedure Create_Log_File(Sender: TObject);
    procedure Read_Ini_File(Sender: TObject);
    procedure Write_Ini_File(Sender: TObject);
  end;

var
  frmDetectKeys         : TfrmDetectKeys;
  FWin_Handle           : Cardinal;
  hkHook                : hHook;
  myLog                 : TAZLog;
  iCurrent_State        : Integer;

  App_Root_Path         : TFileName;
  App_Path              : TFileName;
  Log_Path              : TFileName;
  ini_File_Name         : TFileName;

  log_Level             : TLog_Level;

//---------------------------------------------------------------------------------------------------------------------

implementation

{$R *.dfm}
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
{$ifDef Use_Keyboard_Hook}
function LowLevelKeyboardProc(code: Integer; WParam: WParam; LParam: LParam): LRESULT stdcall;
const
  LLKHF_UP = $0080;     //key-up and key-down are the most basic keyboard events. Select key_up for this app.
var
  Hook: pKBDLLHOOKSTRUCT;
  bControlKeyDown: Boolean;
begin
  try
    Hook := pKBDLLHOOKSTRUCT(LParam);
    case code of
      HC_ACTION:  begin
                    if (Hook^.flags and LLKHF_UP) <> 0 then  begin
                        if (Log_Level = ll_CapsNumlock) then begin
                          if Hook.vkCode in [VK_NUMLOCK, VK_CAPITAL] then
                            PostMessage(frmDetectKeys.Handle, WM_UpdateIcon, Hook.vkCode, 0);
                        end
                        else begin
                            PostMessage(frmDetectKeys.Handle, WM_UpdateIcon, Hook.vkCode, 0);
                        end;
                    end;
                  end;
    end;
  finally
    Result := CallNextHookEx(hkHook, code, WParam, LParam);
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure Enable_Keyboard_Hook;
begin
  hkHook := SetWindowsHookEx(WH_KEYBOARD_LL, @LowLevelKeyboardProc, hInstance, 0);
end;
//---------------------------------------------------------------------------------------------------------------------
procedure Disable_Keyboard_Hook;
begin
  UnHookWindowsHookEx(hkHook);
end;
{$EndIf}
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
function Get_Char_From_VKey(V_Key: Word): string;
// translate virtual keycodes into ASCII char using Windows API call ToAscii
var
    keyboardState: TKeyboardState;
    asciiResult: Integer;
begin
    GetKeyboardState(keyboardState) ;
    SetLength(Result, SizeOf(Char)) ;
    asciiResult := Winapi.Windows.ToAscii(V_Key, MapVirtualKey(V_Key, 0), keyboardState, @Result[1], 0) ;
    case asciiResult of
      0: Result := '';
      1: SetLength(Result, 1) ;
      2:;
      else
        Result := '';
    end;
end;
//---------------------------------------7------------------------------------------------------------------------------
procedure TfrmDetectKeys.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Write_Ini_File(Sender);
  myLog.FlushBuffer;
  myLog.Destroy;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.FormCreate(Sender: TObject);
begin
  Load_Icon(Sender, 'a_mainicon');
  Read_Ini_File(Sender);
  Create_Log_File(Sender);
  {$ifDef Use_Keyboard_Hook}
  Enable_Keyboard_Hook;
  {$endIf}
  {$ifDef Use_Timer}
  Check_Key(Sender);
  Init_Timer(Sender);
  {$EndIf}
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Init_Timer(Sender: TObject);
begin
  with tmr_1 do begin
    Interval  := 1000;
    OnTimer   := Check_Key;

    {$ifDef Use_Timer}
    Enabled   := True;
    {$Else}
    Enabled   := False;
    {$Endif}

  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Check_Key(Sender: TObject);
var
  iState : Integer;
  isNew  : boolean;
begin

  isNew := (Sender = frmDetectKeys);  //first call comes from frmDetectKeys, all subsequent calls just modify the notification tray icon
  iState := GetKeyState(VK_NUMLOCK);

  if iState <> iCurrent_State then begin
    iCurrent_State := iState;
    if (iState = Toggled_ON) then begin
      Show_In_Tray(Sender,isNew,'NumLock_On');
      myLog.WriteGlobal(strlNumlock_On);
    end
    else begin
      Show_In_Tray(Sender,isNew,'NumLock_Off');
      myLog.WriteGlobal(strlNumlock_Off);
    end;
  end;

end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Key_Up_Detected(var Msg: TMessage);
begin
  Check_Key(nil);
  myLog.WriteGlobal(Concat('Key up detected. Key wParam = ',Get_Char_From_VKey(msg.WParam)));
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.FormDestroy(Sender: TObject);
begin
  {$ifDef Use_Keyboard_Hook}
  Disable_Keyboard_Hook;
  {$EndIf}
  Shell_NotifyIcon(NIM_DELETE, @TrayIconData);
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Show_In_Tray(Sender: TObject;const isNew: boolean; const iconName: String);
begin
  with TrayIconData do begin
    cbSize  := System.SizeOf(TrayIconData);
    Wnd     := Handle;
    uID     := 0;
    uFlags  := NIF_MESSAGE + NIF_ICON + NIF_TIP;
    uCallbackMessage := WM_ICONTRAY;
    Load_Icon(Sender, iconName);
    hIcon := Application.Icon.Handle;
    StrPCopy(szTip, Application.Title);
  end;
  if isNew then begin
    Shell_NotifyIcon(NIM_ADD, @TrayIconData);
  end
  else begin
    Shell_NotifyIcon(NIM_MODIFY, @TrayIconData);
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Load_Icon(Sender: TObject; const IconName: String);
begin
  Application.Icon.Handle := LoadIcon(hInstance,pChar(IconName));
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.mnuExitClick(Sender: TObject);
begin
  close;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.mnuOptionsClick(Sender: TObject);
var
  frmOptions  : TfrmOptions;
begin
  frmOptions := TfrmOptions.Create(Self);
  with frmOptions do begin
    Caption                 := strlOptionsCaption;
    RadioGroup1.ItemIndex   := Integer(log_Level);
    ShowModal;

    case ModalResult of
      mrOK: begin
              Log_Level := TLog_Level(RadioGroup1.ItemIndex);
            end;
    end; //case
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.IconResponse(var Msg: TMessage);
var
  pt: TPoint;
begin
  case Msg.lParam of
    WM_LBUTTONDOWN: begin
      // Do nothing
                    end;
    WM_RBUTTONDOWN: begin
                      GetCursorPos(pt);
                      pmnu.Popup(pt.x, pt.y);
                    end;
  end; //case
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Create_Log_File(Sender: TObject);
begin
  myLog := TAZLog.Create;
  with myLog do begin
    LogFileDir  := log_Path;
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure TfrmDetectKeys.Read_Ini_File(Sender: TObject);
var
  iniFile   : TIniFile;
begin
  iniFile := TiniFile.Create(ini_File_Name);
  try
    with iniFile do begin
      Log_Level         := TLog_Level(ReadInteger(strlSettings,strlLogLevel,0));
    end;
  finally
    iniFile.Free;
  end;
end;
//--------------------------------------------------------------------------------------f-------------------------------
procedure TfrmDetectKeys.Write_Ini_File(Sender: TObject);
var
  iniFile   : TIniFile;
begin
  if FileExists(ini_File_Name) then
    DeleteFile(ini_File_Name);
  iniFile := TiniFile.Create(ini_File_Name);
  try
    with iniFile do begin
      WriteString(strlHeader,strlProgInfo,strlProgramInformation);
      WriteInteger(strlSettings,strlLogLevel,Integer(Log_Level));
    end;
  finally
    iniFile.Free;
  end;
end;
//--------------------------------------------------------------------------------------f-------------------------------
initialization
// ensure various directories exists and if unable to create, report error
  App_Root_Path := Concat(strAddSlash(strGetSpecialFolder(CSIDL_Common_Documents)),strCompany,_Back_Slash);
  if Not System.SysUtils.DirectoryExists(App_Root_Path) then begin
    if NOT System.SysUtils.CreateDir(App_Root_Path) then
      MessageDlg(Concat(strlDirCreateErr,App_Root_Path),mtError,[mbok],0);
  end;

  App_Path := Concat(App_Root_Path,strAppTitle,_Back_Slash);
  if Not System.SysUtils.DirectoryExists(App_Path) then begin
    if NOT System.SysUtils.CreateDir(App_Path) then
      MessageDlg(Concat(strlDirCreateErr ,App_Path),mtError,[mbOK],0);
  end;

  Log_Path        := Concat(App_Path,'Log_Files\');
  if Not System.SysUtils.DirectoryExists(Log_Path) then begin
    if NOT System.SysUtils.CreateDir(Log_Path) then
      MessageDlg(Concat(strlDirCreateErr, Log_Path),mtError,[mbok],0);
  end;

  ini_File_Name   := Concat(App_Path,System.IOUtils.TPath.GetFileNameWithoutExtension(Application.exename),'.ini');

  iCurrent_State  := -1;
//---------------------------------------------------------------------------------------------------------------------
finalization
//---------------------------------------------------------------------------------------------------------------------
end.
