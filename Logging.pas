//---------------------------------------------------------------------------------------------------------------------
//-- Simple line-based event logging wrapper
//-- Needs Build.inc to get application name and dates
//-- Used in most AZ applications
//---------------------------------------------------------------------------------------------------------------------
unit Logging;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.sysutils,
  Messages,
  myProcs;

{$i build.inc}

const
  TEXTWIDTH = 140;

type
  TazLog  = Class

  private
    fGlobalLogFile                  :   TFileName;
    fGloballogTextFile              :   TextFile;
    fLogFileDir                     :   String;
    fOnDateRollOver                 :   TNotifyEvent;
    function CreateLogFileName      :   TFileName;
    procedure SetLogFileDir(s: String);
    procedure WriteGlobalHeader;
    procedure Write_Date_Rollover;
  public
    constructor Create;
    destructor  Destroy; Override;
    procedure FlushBuffer;
    procedure WriteGlobal(s: String);
    property LogFileDir: String read fLogFileDir write SetLogFileDir;       //assigning the path will create the file
    property GlobalLogFileName: TFileName read fGlobalLogFile;
    procedure Verify_File;
    property onDateRollOver: TNotifyEvent read fOnDateRollOver write fOnDateRollOver;
  End;

implementation

//--------------------------------------------------------------------------------------------------
constructor TazLog.Create;
begin
  inherited Create;
end;
//--------------------------------------------------------------------------------------------------
destructor TazLog.destroy;
begin
  flush(fGlobalLogTextFile);
  closefile(fGlobalLogtextFile);
  inherited destroy;
end;
//--------------------------------------------------------------------------------------------------
procedure tazlog.Verify_File;
begin
  if fGlobalLogFile <> CreateLogFileName then begin   //date changed while logging was in progess
    flush(fGlobalLogTextFile);
    closefile(fGlobalLogtextFile);                    //close the old file
    SetLogFileDir(fLogFileDir);                       //open the new one, usin the same directory
    Write_Date_Rollover;
    if assigned(onDateRollOver) then
      onDateRollOver(nil);
  end;
end;
//--------------------------------------------------------------------------------------------------
procedure tazLog.FlushBuffer;
begin
  Flush(fGlobalLogTextFile);
end;
//--------------------------------------------------------------------------------------------------
function tazLog.CreateLogFileName: TFileName;
//creates a valid log file name, fully qualified
//output format \logfiledir\Day_of_week_mmddyy.log
var
  str1, str2  : String;
  MyDate      : TDateTime;
  weekday     : String;
begin
  MyDate:=  now; //StrToDateTime(DateTimeToStr(now));
  case DayOfWeek(MyDate) of
    1: weekday  :='Sunday';
    2: weekday  :='Monday';
    3: weekday  :='Tuesday';
    4: weekday  :='Wednesday';
    5: weekday  :='Thursday';
    6: weekday  :='Friday';
    7: weekday  :='Saturday';
  end;

  str1    := weekday;
  str2    := FormatDateTime('mmddyy',Date);
  Result  := Concat(strAddSlash(fLogFileDir),str1,'_',str2,'.','log');

end;
//--------------------------------------------------------------------------------------------------
procedure TazLog.SetLogFileDir(s: String);
begin
  if NOT DirectoryExists(s) then begin   //create the log file directory if it does not yet exist
    if NOT CreateDir(s) then begin
      MessageBox(0,pWideChar('Error creating Log file directory.'),pWideChar('Error'),MB_OK+MB_ICONWARNING);
      exit;
    end;
  end;
  if DirectoryExists(s) then begin
    fLogFileDir := s;
    fGlobalLogFile  := CreateLogFileName;
    if boolCanOpenfile(fGlobalLogFile) then begin
      AssignFile(fGlobalLogtextFile,fGlobalLogFile);
      Append(fGlobalLogtextFile);
    end
    else begin
      AssignFile(fGlobalLogtextFile,fGlobalLogFile);
      rewrite(fGlobalLogtextFile);
    end;
    WriteGlobalHeader;
  end;
end;
//--------------------------------------------------------------------------------------------------
procedure TazLog.WriteGlobal(s: String);
begin
  Writeln(fGlobalLogtextFile,Concat(strCopyFirstN2(s,TEXTWIDTH,'.'),#32, TimeToStr(Time)));
  flush(fGlobalLogtextFile);
end;
//--------------------------------------------------------------------------------------------------
procedure TazLog.Write_Date_Rollover;
const
  strlDateRollOver  = '--- Date Rollover occured: ';
  strlBuildNo       = ' - Build Number: ';
begin
  Writeln(fGlobalLogTextFile,strCopyFirstN2('-',TEXTWIDTH,'-'));
  Writeln(fGlobalLogTextFile,strCopyFirstN2(Concat(strlDateRollover, strAppTitle, strlBuildNo ,strVersion),TEXTWIDTH,'-'));
  Writeln(fGlobalLogTextFile,strCopyFirstN2('-',TEXTWIDTH,'-'));
end;
//--------------------------------------------------------------------------------------------------
procedure TazLog.WriteGlobalHeader;
const
  _MaxNameChars = 50;
  strlProgStart = '--- Program launched: ';
  strlBuildNo   = ' - Build Number/Build Date: ';
  strlDate      = '--- Date ';
  strlTime      = ' Time: ';
  strlUsername  = '--- Username: ';
  strlHasAdmin  = ' HasAdminPrivilege: ';

var
 strUserName       :   String;
 pName             :   pChar;
 wNameChars        :   DWord;

begin
  wNameChars  := _MaxNameChars;
  GetMem(pName,wNameChars);
  if GetUserName(pName,wNameChars) then
    strUserName := String(pName)
  else
    strUserName := 'unknown';
  Writeln(fGlobalLogTextFile,strCopyFirstN2('-',TEXTWIDTH,'-'));
  Writeln(fGlobalLogTextFile,strCopyFirstN2(Concat(strlProgStart, strAppTitle, #32,strlBuildNo,#32,strVersion,'/',strBuildDate),TEXTWIDTH,'-'));
  Writeln(fGlobalLogTextFile,strCopyFirstN2(Concat(strlDate, DateToStr(Date),strlTime, TimeToStr(Time)),TEXTWIDTH,'-'));
  Writeln(fGlobalLogTextFile,strCopyFirstN2(Concat(strlUserName, strUserName,strlHasAdmin,IntToStr(Integer(isWindowsAdmin))),TEXTWIDTH,'-'));
  Writeln(fGlobalLogTextFile,strCopyFirstN2('-',TEXTWIDTH,'-'));
end;
//----------------------------------------------------------------------------------------------------------------------
initialization
  System.sysutils.FormatSettings.LongTimeFormat := 'hh nn ss.zzz';
//---------------------------------------------------------------------------------------------------------------------
finalization
//---------------------------------------------------------------------------------------------------------------------
end.
