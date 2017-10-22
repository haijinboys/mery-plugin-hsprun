unit HSPCmp;

interface

uses
{$IF CompilerVersion > 22.9}
  Winapi.Windows, System.SysUtils;
{$ELSE}
  Windows, SysUtils;
{$IFEND}


const
  Debug = 1;
  Release = 2;

type
  THSCIni = function(Arg1: Integer; Arg2: PAnsiChar; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSCRefName = function(Arg1: Integer; Arg2: PAnsiChar; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSCObjName = function(Arg1: Integer; Arg2: PAnsiChar; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSCComPath = function(Arg1: Integer; Arg2: PAnsiChar; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSCComp = function(Arg1: Integer; Arg2: Integer; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSCGetMes = function(Arg1: PAnsiChar; Arg2: Integer; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSCBye = function(Arg1: Integer; Arg2: Integer; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSC3Make = function(Arg1: Integer; Arg2: PAnsiChar; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSC3GetRuntime = function(Arg1: PAnsiChar; Arg2: PAnsiChar; Arg3: Integer; Arg4: Integer): Boolean; stdcall;
  THSC3Run = function(Arg1: PAnsiChar; Arg2: Integer; Arg3: Integer; Arg4: Integer): Boolean; stdcall;

function Execute(const HSPDirName: AnsiString; const ScriptFileName: AnsiString; const RefScriptFileName: AnsiString; Mode: Integer; DebugWindow: Boolean): Boolean;

var
  HSCIni: THSCIni;
  HSCRefName: THSCRefName;
  HSCObjName: THSCObjName;
  HSCComPath: THSCComPath;
  HSCComp: THSCComp;
  HSCGetMes: THSCGetMes;
  HSCBye: THSCBye;
  HSC3Make: THSC3Make;
  HSC3GetRuntime: THSC3GetRuntime;
  HSC3Run: THSC3Run;

implementation

function Execute(const HSPDirName: AnsiString; const ScriptFileName: AnsiString; const RefScriptFileName: AnsiString; Mode: Integer; DebugWindow: Boolean): Boolean;
var
  ScriptDirName, CommonDirPath, ObjFileName, RunTimeDirName, ExecCommand: AnsiString;
  RunTimeFileName, ObjFileShortName: array [0 .. 1024] of AnsiChar;
  ErrorMessage: array [0 .. 32000] of AnsiChar;
begin
  ScriptDirName := AnsiString(ExtractFilePath(string(ScriptFileName)));
  SetCurrentDirectoryA(PAnsiChar(ScriptDirName));
  if Mode = Release then
    ObjFileName := ScriptDirName + 'start.ax'
  else
    ObjFileName := ScriptDirName + 'obj';
  HSCIni(0, PAnsiChar(ScriptFileName), 0, 0);
  HSCRefName(0, PAnsiChar(RefScriptFileName), 0, 0);
  HSCObjName(0, PAnsiChar(ObjFileName), 0, 0);
  CommonDirPath := HSPDirName + 'common\';
  HSCComPath(0, PAnsiChar(CommonDirPath), 0, 0);
  if ((Mode = Release) and (HSCComp(0, 4, 0, 0))) or (HSCComp(1, 0, Integer(DebugWindow), 0)) then
  begin
    HSCGetMes(@ErrorMessage, 0, 0, 0);
    MessageBoxA(0, ErrorMessage, PAnsiChar('Mery'), MB_OK or MB_ICONEXCLAMATION or MB_TASKMODAL);
    Result := False;
    Exit;
  end;
  if Mode = Release then
  begin
    RunTimeDirName := HSPDirName + 'runtime';
    if HSC3Make(0, PAnsiChar(RunTimeDirName), 0, 0) then
    begin
      MessageBoxA(0, PAnsiChar('実行ファイルの作成に失敗しました。'), PAnsiChar('Mery'), MB_OK or MB_ICONEXCLAMATION or MB_TASKMODAL);
      Result := False;
      Exit;
    end
    else
    begin
      MessageBoxA(0, PAnsiChar('実行ファイルを作成しました。'), PAnsiChar('Mery'), MB_OK or MB_ICONINFORMATION or MB_TASKMODAL);
      Result := True;
      Exit;
    end;
  end
  else
  begin
    HSC3GetRunTime(@RunTimeFileName, PAnsiChar(ObjFileName), 0, 0);
    if RuntimeFileName = '' then
      RuntimeFileName := 'hsp3';
    GetShortPathNameA(PAnsiChar(ObjFileName), ObjFileShortName, 1024);
    ExecCommand := HSPDirName + '\' + RuntimeFileName + ' ' + ObjFileShortName;
    if HSC3Run(PAnsiChar(ExecCommand), 0, 0, 0) then
    begin
      MessageBoxA(0, PAnsiChar('ランタイムファイルが見つかりません。'), PAnsiChar('Mery'), MB_OK or MB_ICONEXCLAMATION or MB_TASKMODAL);
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

end.
