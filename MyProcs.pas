//---------------------------------------------------------------------------------------------------------------------
//
//      MyProcs - Collection of routines and functions
//      Work in progress...add as required
//      Compiler: Delphi 10 (2016)
//      Author: Josef Goergen
//      Conventions:
//      - Constants start with _ and are separated into individual words via _
//      - function and procedure names are NOT word separated
//      - fucntion return values are indicated via prefix (str for string, int for 4-byte integer, w for Word, etc.)
//
//---------------------------------------------------------------------------------------------------------------------
unit MyProcs;

{$D+}

interface

uses
  Winapi.Windows,
  System.Classes,
  Vcl.Forms,
  sysUtils,
  strUtils,
  ShellAPI,
  Math;

  //-----------------------------------------------------------------------------
  //-- IP Address Types
  //-----------------------------------------------------------------------------
const
  IPv4BitSize = SizeOf(Byte) * 4 * 8;
  IPv6BitSize = SizeOf(Word) * 8 * 8;
  IPv4_Byte : Set of Byte = [0..255];

type
  T4 = 0..3;
  T8 = 0..7;
  TIPv4ByteArray = array[T4] of Byte;
  TIPv6WordArray = array[T8] of Word;

  TIPv4 = packed record
    case Integer of
      0: (D, C, B, A: Byte);
      1: (Groups: TIPv4ByteArray);
      2: (Value: Cardinal);
  end;

  TIPv6 = packed record
    case Integer of
      0: (H, G, F, E, D, C, B, A: Word);
      1: (Groups: TIPv6WordArray);
  end;
  //-----------------------------------------------------------------------------

  //--- for debugger detection ---
  type
    PPeb = ^TPeb;
    TPeb = packed record
      InheritedAddressSpace         : Boolean;
      ReadImageFileExecOptions      : Boolean;
      BeingDebugged                 : Boolean;
    end;
  //-----------------------------------------------------------------------------

  TScreenColor  = ( scUnknown, scMonoChrome, sc16Color, sc256Color,
                    scHiColor, scTrueColor );

const
  _NULL                 = #0;
  _TAB                  = #9;
  _CR                   = #13;
  _ESC                  = #27;
  _LF                   : UTF8String = #10;
  _Back_Slash           = '\';
  _Hex_Prefix           = '$';
  _CRLF                 : UTF8String = #13 + #10;
  _Comma                = #44;
  _NUMBERS              : set of char = ['0'..'9'];                 //Numerals

//var

//---------------------------------------------------------------------------------------------------------------------
// -- Shell Execution
//---------------------------------------------------------------------------------------------------------------------
procedure ExecuteAndWait(const aCommand: String);
//---------------------------------------------------------------------------------------------------------------------
// -- Folders and Path Names
//---------------------------------------------------------------------------------------------------------------------
function strGetSpecialFolder(const folder: Integer): string;
function strAddSlash(const S: String): String;
function strLastCh(const S: String): Char;
function StrToIPv6(const S: String; var IPv6_Store: TIPv6): Boolean;
function StrToIPv4(const S: String; var IPv4_Store: TIPv4): boolean;
function strNiceInteger(const S: String): String; overload;
function strNiceInteger(const n: Integer): String; overload;
function strNicePath(const myPath: String; const _maxChar: Integer): String;
function strCopyFirstN2(const s: String; const n: Integer; const padChar: Char): String;
function strMake(C: Char; Len: Integer): String;
function strPadChL(const S: String; C: Char; Len: Integer): String;
function strPadChR(const S: String; C: Char; Len: Integer): String;
function ExtractPathAndName(const Filename: String): String;
procedure ShowDirectory(const iHandle: Integer; const strDir: TFilename);
procedure ShowInNotePad(const iHandle: Integer; const s: String);
//---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------------------
// -- Files
//---------------------------------------------------------------------------------------------------------------------
function boolCanOpenFile(const aName: String): boolean;
function LoadFileToString(const fileName: TFIleName): AnsiString;
function LoadFileToStringW(const fileName: TFIleName): String;

//---------------------------------------------------------------------------------------------------------------------
// -- Miscellaneous
//---------------------------------------------------------------------------------------------------------------------
function GetAppVersionStr: string;
function sysScreenColor: TScreenColor;
procedure sysDelay(aMs: Cardinal);
function IsDebuggerPresent : Boolean;
function IsWindowsAdmin: Boolean;
function fileShellOpen(const aFile: String): Boolean;
function FindWindow_Partial_Title(const Partial_Title: String): HWND;

implementation

uses
  SHFolder;

//---------------------------------------------------------------------------------------------------------------------
procedure ExecuteAndWait(const aCommand: string);
var
  tmpStartupInfo        : TStartupInfo;
  tmpProcessInformation : TProcessInformation;
  tmpProgram            : String;
begin
  tmpProgram := trim(aCommand);
  FillChar(tmpStartupInfo, SizeOf(tmpStartupInfo), 0);
  with tmpStartupInfo do begin
    cb := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
  end;

  if CreateProcess(nil, pchar(tmpProgram), nil, nil, true, CREATE_NO_WINDOW, nil, nil, tmpStartupInfo, tmpProcessInformation) then begin
    // loop every 10 ms
    while WaitForSingleObject(tmpProcessInformation.hProcess, 10) > 0 do begin
      Application.ProcessMessages;
    end;
    CloseHandle(tmpProcessInformation.hProcess);
    CloseHandle(tmpProcessInformation.hThread);
  end
  else begin
    RaiseLastOSError;
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure ShowInNotePad(const iHandle: Integer; const s: String);
begin
  if boolCanOpenFile(s) then
    ShellExecute(iHandle,'open', 'c:\windows\notepad.exe',pWchar(s), nil, SW_SHOWNORMAL) ;
end;
//---------------------------------------------------------------------------------------------------------------------
function fileShellOpen(const aFile: String): Boolean;
var
  Tmp: array[0..100] of char;
begin
  Result := ShellExecute( Application.Handle,
    'open', StrPCopy(Tmp,aFile), nil, nil, SW_NORMAL) > 32;
end;
//---------------------------------------------------------------------------------------------------------------------
function strNiceInteger(const S: String): String; Overload;
const
  _ThouSep  = ',';
var
 i,j,k   : Integer;
begin
 j := Length(S) div 3;
 k := Length(S) - (j * 3);
 Result  := '';
 case k of
     0     : begin
               for i := 1 to (j-1) do
                 Result  := Concat(_ThouSep,Copy(S,Length(S)-i*3,3),Result);
               Result   := Concat(Copy(S,Length(S)-j*3,3),Result)
             end;
     else    begin
               for i := 1 to j do
                 Result  := Concat(_ThouSep,Copy(S,Length(S)-i*3+1,3),Result);
               Result    := Concat(Copy(S,1,k),Result);
             end;
 end; //case
end;
//---------------------------------------------------------------------------------------------------------------------
function strNiceInteger(const n: Integer): String; Overload;
const
  _ThouSep  = ',';
var
 i,j,k    : Integer;
  s       : String;
begin
 s := IntToStr(n);
 j := Length(S) div 3;
 k := Length(S) - (j * 3);
 Result  := '';
 case k of
     0     : begin
               for i := 1 to (j-1) do
                 Result  := Concat(_ThouSep,Copy(S,Length(S)-i*3,3),Result);
               Result   := Concat(Copy(S,Length(S)-j*3,3),Result)
             end;
     else    begin
               for i := 1 to j do
                 Result  := Concat(_ThouSep,Copy(S,Length(S)-i*3+1,3),Result);
               Result    := Concat(Copy(S,1,k),Result);
             end;
 end; //case
end;
//---------------------------------------------------------------------------------------------------------------------
function strAddSlash(const S: String): String;
begin
  Result:=S;
  if Result<>'' then
     if strLastCh(Result)<>_Back_Slash then Result:=Result+_Back_Slash;
end;
//---------------------------------------------------------------------------------------------------------------------
function  strLastCh(const S: String): Char;
begin
  Result:=S[Length(S)];
end;
//---------------------------------------------------------------------------------------------------------------------
function strGetSpecialFolder(const folder: Integer): string;
// CSIDL_Appdata            --> c:\ProgramData\
// CSIDL_Local_AppData      --> c:\Users\Username\AppData\Local\
// CSIDL_Common_AppData     --> c:\Users\Username\AppData\Roaming\
// CSIDL_COMMON_DOCUMENTS   --> c:\Users\Username\Documents\
// CSIDL_Personal           --> c:\Users\....not sure
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0,folder,0,SHGFP_TYPE_CURRENT,@path[0])) then
    Result := path
  else
    Result := '';
end;
//----------------------------------------------------------------------------------------------------------------------
function StrToIPv4(const S: String; var IPv4_Store: TIPv4): boolean;
var
  SIP: String;
  Start: Integer;
  I: T4;
  Index: Integer;
  Count: Integer;
  SGroup: String;
  G: Integer;
begin
  result  := false;
  SIP := S + '.';
  Start := 1;
  for I := High(T4) downto Low(T4) do begin
    Index := PosEx('.', SIP, Start);
    if Index = 0 then
      exit;
    Count := Index - Start + 1;
    SGroup := Copy(SIP, Start, Count - 1);
    if TryStrToInt(SGroup, G) then begin
        if NOT (G in IPv4_Byte) then  //check in range 0..255
          exit;
        if (I = Low(T4)) and (G = 0) then   //check in range 1..255
          exit;
        IPv4_Store.Groups[I] := G;
      end
      else begin
        exit;
      end;
    Inc(Start, Count);
  end;
  Result  := True;
end;
//---------------------------------------------------------------------------------------------------------------------
function StrToIPv6(const S: String; var IPv6_Store: TIPv6): Boolean;
{ Valid examples for S:
  2001:0db8:85a3:0000:0000:8a2e:0370:7334
  2001:db8:85a3:0:0:8a2e:370:7334
  2001:db8:85a3::8a2e:370:7334
  ::8a2e:370:7334
  2001:db8:85a3::
  ::1
  ::
  ::ffff:c000:280
  ::ffff:192.0.2.128 }
var
  ZeroPos : Integer;
  DotPos  : Integer;
  SIP     : String;
  Start   : Integer;
  Index   : Integer;
  Count   : Integer;
  SGroup  : String;
  G       : Integer;
  //---------------------------------------------------------------------------
  function NormalNotation: Boolean;
  var
    I: T8;
  begin
    Result  := True;
    SIP := S + ':';
    Start := 1;
    for I := High(T8) downto Low(T8) do begin
      Index := PosEx(':', SIP, Start);
      if Index = 0 then begin
        Result  := False;
        exit;
        //IPv6ErrorFmt(SInvalidIPv6Value, S);
      end;
      Count := Index - Start + 1;
      SGroup := '$' + Copy(SIP, Start, Count - 1);
      if not TryStrToInt(SGroup, G) or (G > High(Word)) or (G < 0) then begin
        //IPv6ErrorFmt(SInvalidIPv6Value, S);
        Result  := False;
        exit;
      end;
      IPv6_Store.Groups[I] := G;
      Inc(Start, Count);
    end;
  end;

  //---------------------------------------------------------------------------
  function CompressedNotation: Boolean;
  var
    I: T8;
    A: array of Word;
  begin
    Result  := True;
    SIP := S + ':';
    Start := 1;
    I := High(T8);
    while Start < ZeroPos do
    begin
      Index := PosEx(':', SIP, Start);
      if Index = 0 then begin
        //IPv6ErrorFmt(SInvalidIPv6Value, S);
        Result  := False;
        exit;
      end;
      Count := Index - Start + 1;
      SGroup := '$' + Copy(SIP, Start, Count - 1);
      if not TryStrToInt(SGroup, G) or (G > High(Word)) or (G < 0) then begin
        //IPv6ErrorFmt(SInvalidIPv6Value, S);
        Result  := False;
        exit;
      end;
      IPv6_Store.Groups[I] := G;
      Inc(Start, Count);
      Dec(I);
    end;
    FillChar(IPv6_Store.H, (I + 1) * SizeOf(Word), 0);
    if ZeroPos < (Length(S) - 1) then
    begin
      SetLength(A, I + 1);
      Start := ZeroPos + 2;
      repeat
        Index := PosEx(':', SIP, Start);
        if Index > 0 then
        begin
          Count := Index - Start + 1;
          SGroup := '$' + Copy(SIP, Start, Count - 1);
          if not TryStrToInt(SGroup, G) or (G > High(Word)) or (G < 0) then begin
            //IPv6ErrorFmt(SInvalidIPv6Value, S);
            Result  := False;
            exit;
          end;
          A[I] := G;
          Inc(Start, Count);
          Dec(I);
        end;
      until Index = 0;
      Inc(I);
      Count := Length(A) - I;
      Move(A[I], IPv6_Store.H, Count * SizeOf(Word));
    end;
  end;
  //---------------------------------------------------------------------------
  function DottedQuadNotation: boolean;
  var
    I: T4;
  begin
    Result  := True;
    if UpperCase(Copy(S, ZeroPos + 2, 4)) <> 'FFFF' then begin
      Result := False;
      exit;
      //IPv6ErrorFmt(SInvalidIPv6Value, S);
    end;
    FillChar(IPv6_Store.E, 5 * SizeOf(Word), 0);
    IPv6_Store.F := $FFFF;
    SIP := S + '.';
    Start := ZeroPos + 7;
    for I := Low(T4) to High(T4) do
    begin
      Index := PosEx('.', SIP, Start);
      if Index = 0 then begin
        //IPv6ErrorFmt(SInvalidIPv6Value, S);
        Result  := False;
        exit;
      end;
      Count := Index - Start + 1;
      SGroup := Copy(SIP, Start, Count - 1);
      if not TryStrToInt(SGroup, G) or (G > High(Byte)) or (G < 0) then begin
        //IPv6ErrorFmt(SInvalidIPv6Value, S);
        Result  := False;
        exit;
      end;
      case I of
        0: IPv6_Store.G := G shl 8;
        1: Inc(IPv6_Store.G, G);
        2: IPv6_Store.H := G shl 8;
        3: Inc(IPv6_Store.H, G);
      end;
      Inc(Start, Count);
    end;
  end;
  //---------------------------------------------------------------------------
begin
  ZeroPos := Pos('::', S);
  if ZeroPos = 0 then
    Result := NormalNotation
  else begin
    DotPos := Pos('.', S);
    if DotPos = 0 then
      Result := CompressedNotation
    else
      Result := DottedQuadNotation;
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
function  boolCanOpenFile(const aName: String): boolean;
var
  LHdlFile: THandle;
begin
  Result := False;
  if FileExists(aName) then begin
    LHdlFile := FileOpen(aName, fmOpenRead or fmShareDenyNone);
    if LHdlFile <> INVALID_HANDLE_VALUE then begin
      CloseHandle(LHdlFile);
      Result := True;
    end;
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
function LoadFileToString(const fileName: TFIleName): AnsiString;
var
  FileStream : TFileStream;
begin
  FileStream:= TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);    //fmShareDenyNone flag is crucial for non-exclusive file access
  try
    if FileStream.Size>0 then begin
      SetLength(Result, FileStream.Size);
      FileStream.Read(Pointer(Result)^, FileStream.Size);
    end;
    finally
      FileStream.Free;
    end;
end;
//---------------------------------------------------------------------------------------------------------------------
function LoadFileToStringW(const fileName: TFIleName): String;
var
  FileStream : TFileStream;
begin
  FileStream:= TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);    //fmShareDenyNone flag is crucial for non-exclusive file access
  try
    if FileStream.Size>0 then begin
      SetLength(Result, FileStream.Size);
      FileStream.Read(Pointer(Result)^, FileStream.Size);
    end;
    finally
      FileStream.Free;
    end;
end;
//---------------------------------------------------------------------------------------------------------------------
function strMake(C: Char; Len: Integer): String;
begin
  Result:=strPadChL('',C,Len);
end;
//---------------------------------------------------------------------------------------------------------------------
function strNicePath(const myPath: String; const _maxChar: Integer): String;
var
  i,j : Integer;
begin

  result  := myPath;
  i       := Length(Result);
  if i > _maxChar then begin
    Delete(result,1,Pos('\',result));     //myPath looks like 'c:\firstpath\secondPath\'  this line deletes the 'c:\'
    j := Pos('\',Result);                 //position of second \ if present
    if j > 0 then
      j := j + Pos('\',myPath)            // j is index to second \ in myPath
    else
      j := 0;

    Result  := myPath;
    i       := Length(Result);
    while i > 1 do begin
      if Result[i] = '\' then begin
          //Result := Concat('...',Copy(result,i,Length(Result)-1+1),'\');
          Result := Concat('...',Copy(result,i,Length(Result)-1+1));
          break;
      end;
      dec(i);
    end; //while  //at this point we have '...\directory\'...les's see if we can fit the root directory
    if (j + Length(Result)) < _maxChar then
      Result  := Copy(myPath,1,j) + Result
    else
       Result := Concat(Copy(myPath,1,3),Result);
  end; //if i
end;
//---------------------------------------------------------------------------------------------------------------------
function strCopyFirstN2(const s: String; const n: Integer; const padChar: Char): String;
//copies first n characters, followd by ellipses
var
  i   : Integer;
begin
  Result  := strMake(padChar,n+3);
  for i := 1 to Math.Min(length(s),n) do
    Result[i] := s[i];
end;
//----------------------------------------------------------------------------------------------------------------------
function strPadChL(const S: String; C: Char; Len: Integer): String;
begin
  Result:=S;
  while Length(Result)<Len do Result:=C+Result;
end;
//----------------------------------------------------------------------------------------------------------------------
function strPadChR(const S: String; C: Char; Len: Integer): String;
begin
  Result:=S;
  while Length(Result)<Len do Result:=Result+C;
end;
//----------------------------------------------------------------------------------------------------------------------
function GetAppVersionStr: string;
var
  Exe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Exe := ParamStr(0);
  Size := GetFileVersionInfoSize(PChar(Exe), Handle);
  if Size = 0 then
    RaiseLastOSError;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
    RaiseLastOSError;
  if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
    RaiseLastOSError;
  Result := Format('%d.%d.%d.%d',
    [LongRec(FixedPtr.dwFileVersionMS).Hi,  //major
     LongRec(FixedPtr.dwFileVersionMS).Lo,  //minor
     LongRec(FixedPtr.dwFileVersionLS).Hi,  //release
     LongRec(FixedPtr.dwFileVersionLS).Lo]) //build
end;
//---------------------------------------------------------------------------------------------------------------------
function sysScreenColor: TScreenColor;
var
	aDC : hDC;
begin
  Result:= scUnknown;
	aDC := GetDC( 0 );
  try
    case GetDeviceCaps( aDC, BITSPIXEL ) of
      1 : Result := scMonoChrome;
      4	: Result := sc16Color;
      8	: Result := sc256Color;
     16	: Result := scHiColor;
     24	: Result := scTrueColor;
    end;
  finally
  	ReleaseDC( 0, aDC);
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
procedure sysDelay(aMs: Cardinal);
var
  TickCount: Cardinal;
begin
  TickCount := GetTickCount;
  while (GetTickCount - TickCount) < aMs do Application.ProcessMessages;
end;
//---------------------------------------------------------------------------------------------------------------------
function IsWindowsAdmin: Boolean;
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5)) ;
const
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
var
  hAccessToken: THandle;
  ptgGroups: PTokenGroups;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  g: Integer;
  bSuccess: BOOL;
begin
  Result := False;

  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken) ;
  if not bSuccess then begin
    if GetLastError = ERROR_NO_TOKEN then
    bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken) ;
  end;

  if bSuccess then begin
    GetMem(ptgGroups, 1024) ;

    bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize) ;

    CloseHandle(hAccessToken) ;

    if bSuccess then begin
      AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, psidAdministrators) ;
      {$RANGECHECKS OFF}
      for g := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[g].Sid) then begin
          Result := True;
          Break;
        end;
      {$RANGECHECKS ON}
      FreeSid(psidAdministrators) ;
    end;
    FreeMem(ptgGroups) ;
  end;
end;
//----------------------------------------------------------------------------------------------------------------------
function IsDebuggerPresent : Boolean;
var
  PEB : PPEB;
  LPEB : TPEB;
begin
asm
 push eax
 mov eax,fs: $30;
 mov PEB, eax
 pop eax
end;
  LPEB := TPEB(PEB^);
  if LPEB.BeingDebugged then
    Result := True
  else
    Result := False;
end;
//---------------------------------------------------------------------------------------------------------------------
function ExtractPathAndName(const Filename: String): String;
begin
  result  := Filename;
  Delete(Result, Pos(ExtractFileExt(FileName),FileName), Length(ExtractFileExt(FileName)));
end;
//---------------------------------------------------------------------------------------------------------------------
procedure ShowDirectory(const iHandle: Integer; const strDir: TFilename);
begin
  ShellExecute(iHandle,'open','explorer.exe',pchar(strDir),nil,SW_SHOW);
end;
//---------------------------------------------------------------------------------------------------------------------
function FindWindow_Partial_Title(const Partial_Title: String): HWND;
var
  hWndTemp: hWnd;
  iLenText: Integer;
  cTitletemp: Array [0..254] of Char;
  sTitleTemp: String;
  my_Title  : String;
begin
  Result   := 0;
  hWndTemp := FindWindow(nil, nil);
  while hWndTemp <> 0 do begin
    iLenText      := GetWindowText(hWndTemp, cTitletemp, 255);
    sTitleTemp    := cTitletemp;
    sTitleTemp    := UpperCase(copy( sTitleTemp, 1, iLenText));
    My_Title      := UpperCase(Partial_Title);
    if pos( My_Title, sTitleTemp ) <> 0 then begin
      result := hWndTemp;
      break;
    end;
    hWndTemp := GetWindow(hWndTemp, GW_HWNDNEXT);
  end;
end;
//---------------------------------------------------------------------------------------------------------------------
end.

