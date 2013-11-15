// -----------------------------------------------------------------------------
// HSPコンパイル実行
//
// Copyright (c) Kuro. All Rights Reserved.
// e-mail: info@haijin-boys.com
// www:    http://www.haijin-boys.com/
// -----------------------------------------------------------------------------

library HSPRun;

{$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
{$WEAKLINKRTTI ON}
{$WARN SYMBOL_PLATFORM OFF}


uses
{$IF CompilerVersion > 22.9}
  Winapi.Windows,
  System.SysUtils,
  System.IniFiles,
{$ELSE}
  Windows,
  SysUtils,
  IniFiles,
{$IFEND}
  HSPCmp,
  mCommon in 'mCommon.pas',
  mPlugin in 'mPlugin.pas';

resourcestring
  SName = 'HSPコンパイル実行';
  SVersion = '2.0.3';

const
  IDS_MENU_TEXT = 1;
  IDS_STATUS_MESSAGE = 2;
  IDI_ICON = 101;

{$R *.res}


procedure OnCommand(hwnd: HWND); stdcall;
  procedure SaveToFile(const FileName, S: string);
  var
    Path: string;
    F: TextFile;
  begin
    Path := ExtractFileDir(FileName);
    if (Path <> '') and not DirectoryExists(Path) then
      if not ForceDirectories(Path) then
        raise Exception.Create('ディレクトリ' + Path + 'を作成できません。');
    AssignFile(F, FileName);
    try
      Rewrite(F);
      try
        if Length(S) > 0 then
          WriteLn(F, S);
      finally
        CloseFile(F);
      end;
    except
      on EInOutError do
        raise EInOutError.Create(ExtractFileName(FileName) + #13#10 + 'ファイルに書き込みできません。');
    end;
  end;

var
  H: THandle;
  S: string;
  C: array [0 .. MAX_PATH] of Char;
  Len: NativeInt;
  SelStart, SelEnd, ScrollPoint: TPoint;
  HSPRunFileName: string;
  HSPDirName: string;
  ScriptFileName: string;
  RefScriptFileName: string;
  Mode: NativeInt;
  DebugWindow: Boolean;
begin
  if not GetIniFileName(S) then
    Exit;
  HSPRunFileName := ExtractFilePath(S) + 'Plugins\HSPRun\HSPRun.ini';
  HSPDirName := 'C:\hsp331\';
  Mode := Debug;
  DebugWindow := True;
  with TMemIniFile.Create(HSPRunFileName, TEncoding.UTF8) do
    try
      HSPDirName := IncludeTrailingBackslash(ReadString('HSPRun', 'HSPDirName', HSPDirName));
      Mode := ReadInteger('HSPRun', 'Mode', Mode);
      DebugWindow := ReadBool('HSPRun', 'DebugWindow', DebugWindow);
    finally
      Free;
    end;
  H := LoadLibrary(PChar(HSPDirName + 'hspcmp.dll'));
  if H <> 0 then
  begin
    @HSCIni := GetProcAddress(H, '_hsc_ini@16');
    @HSCRefName := GetProcAddress(H, '_hsc_refname@16');
    @HSCObjName := GetProcAddress(H, '_hsc_objname@16');
    @HSCComPath := GetProcAddress(H, '_hsc_compath@16');
    @HSCComp := GetProcAddress(H, '_hsc_comp@16');
    @HSCGetMes := GetProcAddress(H, '_hsc_getmes@16');
    @HSCBye := GetProcAddress(H, '_hsc_bye@16');
    @HSC3Make := GetProcAddress(H, '_hsc3_make@16');
    @HSC3GetRuntime := GetProcAddress(H, '_hsc3_getruntime@16');
    @HSC3Run := GetProcAddress(H, '_hsc3_run@16');
    Editor_Redraw(hwnd, False);
    try
      Editor_GetSelStart(hwnd, POS_LOGICAL, @SelStart);
      Editor_GetSelEnd(hwnd, POS_LOGICAL, @SelEnd);
      Editor_GetScrollPos(hwnd, @ScrollPoint);
      Editor_ExecCommand(hwnd, MEID_EDIT_SELECT_ALL);
      Len := Editor_GetSelText(hwnd, 0, nil) - 1;
      SetLength(S, Len);
      Editor_GetSelText(hwnd, Len, @S[1]);
      Editor_SetCaretPos(hwnd, POS_LOGICAL, @SelStart);
      Editor_SetCaretPosEx(hwnd, POS_LOGICAL, @SelEnd, True);
      Editor_SetScrollPos(hwnd, @ScrollPoint);
    finally
      Editor_Redraw(hwnd, True);
    end;
    Editor_Info(hwnd, MI_GET_FILE_NAME, LPARAM(@C));
    if C = '' then
      ScriptFileName := ExtractFilePath(ParamStr(0)) + 'hsptmp'
    else
      ScriptFileName := ExtractFilePath(C) + 'hsptmp';
    SaveToFile(ScriptFileName, S);
    if GetKeyState(VK_CONTROL) and $80 > 0 then
    begin
      if Mode = Debug then
        Mode := Release
      else
        Mode := Debug;
    end;
    Execute(AnsiString(HSPDirName), AnsiString(ScriptFileName), AnsiString(RefScriptFileName), Mode, DebugWindow);
    FreeLibrary(H);
  end;
end;

function QueryStatus(hwnd: HWND; pbChecked: PBOOL): BOOL; stdcall;
begin
  pbChecked^ := False;
  Result := True;
end;

function GetMenuTextID: NativeInt; stdcall;
begin
  Result := IDS_MENU_TEXT;
end;

function GetStatusMessageID: NativeInt; stdcall;
begin
  Result := IDS_STATUS_MESSAGE;
end;

function GetIconID: NativeInt; stdcall;
begin
  Result := IDI_ICON;
end;

procedure OnEvents(hwnd: HWND; nEvent: NativeInt; lParam: LPARAM); stdcall;
begin
  //
end;

function PluginProc(hwnd: HWND; nMsg: NativeInt; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  Result := 0;
  case nMsg of
    MP_GET_NAME:
      begin
        Result := Length(SName);
        if lParam <> 0 then
          lstrcpynW(PChar(lParam), PChar(SName), wParam);
      end;
    MP_GET_VERSION:
      begin
        Result := Length(SVersion);
        if lParam <> 0 then
          lstrcpynW(PChar(lParam), PChar(SVersion), wParam);
      end;
  end;
end;

exports
  OnCommand,
  QueryStatus,
  GetMenuTextID,
  GetStatusMessageID,
  GetIconID,
  OnEvents,
  PluginProc;

begin
  // ReportMemoryLeaksOnShutdown := True;

end.
