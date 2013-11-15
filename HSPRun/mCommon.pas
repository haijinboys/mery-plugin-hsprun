unit mCommon;

interface

uses
{$IF CompilerVersion > 22.9}
  Winapi.Windows, System.SysUtils, Vcl.Graphics;
{$ELSE}
  Windows, SysUtils, Graphics;
{$IFEND}


const
  SName = 'Mery';
  shell32 = 'shell32.dll';

function FileExists2(const FileName: string): Boolean;
function DirectoryExists2(const Directory: string): Boolean;
function GetAppDataPath: string;
function GetIniFileName(var FileName: string): Boolean;
function GetInvertColor(Color: TColor): TColor;

function ShellExecute(hWnd: HWND; Operation, FileName, Parameters,
  Directory: PWideChar; ShowCmd: Integer): HINST; stdcall;
function ShellExecute; external shell32 name 'ShellExecuteW';

function SHGetFolderPath(hwnd: HWND; csidl: Integer; hToken: THandle;
  dwFlags: DWORD; pszPath: LPWSTR): HResult; stdcall;
function SHGetFolderPath; external shell32 name 'SHGetFolderPathW';

var
  FIniFailed: Boolean;

implementation

// -----------------------------------------------------------------------------
// �h���C�u�m�F

function IsDriveReady(C: Char): Boolean;
var
  W: Word;
  SR: TSearchRec;
begin
  if C = '\' then
  begin
    Result := True;
    Exit;
  end;
  C := CharUpperW(PChar(string(C)))^;
  W := SetErrorMode(SEM_FAILCRITICALERRORS);
  try
    Result := DiskSize(Ord(C) - $40) <> -1;
    if Result and (GetDriveType(PChar(string(C + ':\'))) in [DRIVE_REMOTE, DRIVE_CDROM]) then
      try
        Result := FindFirst(C + ':\*.*', $3F, SR) = 0;
      finally
        FindClose(SR);
      end;
  finally
    SetErrorMode(W);
  end;
end;

// -----------------------------------------------------------------------------
// �t�@�C�����݊m�F

function FileExists2(const FileName: string): Boolean;
begin
  if Length(FileName) = 0 then
    Result := False
  else
  begin
    if (ExpandFileName(FileName)[1] = '\') or
      IsDriveReady(ExpandFileName(FileName)[1]) then
      Result := FileExists(FileName)
    else
      Result := False;
  end;
end;

// -----------------------------------------------------------------------------
// �f�B���N�g�����݊m�F

function DirectoryExists2(const Directory: string): Boolean;
begin
  if Length(Directory) = 0 then
    Result := False
  else
  begin
    if (ExpandFileName(Directory)[1] = '\') or
      IsDriveReady(ExpandFileName(Directory)[1]) then
      Result := DirectoryExists(Directory)
    else
      Result := False;
  end;
end;

// -----------------------------------------------------------------------------
// �A�v���P�[�V�����f�[�^�p�X�擾

const
  CSIDL_APPDATA = $001A;

function GetAppDataPath: string;
var
  S: array [0 .. MAX_PATH] of Char;
begin
  SetLastError(ERROR_SUCCESS);
  if SHGetFolderPath(0, CSIDL_APPDATA, 0, 0, @S) = S_OK then
    Result := IncludeTrailingPathDelimiter(S);
end;

// -----------------------------------------------------------------------------
// INI�t�@�C�����擾

function GetIniFileName(var FileName: string): Boolean;
begin
  Result := False;
  if not FileExists2(ParamStr(0)) then
    Exit;
  FileName := ChangeFileExt(ParamStr(0), '.ini');
  if not FileExists2(FileName) then
  begin
    FileName := GetAppDataPath + SName + '\' + ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
    ForceDirectories(ExtractFileDir(FileName));
  end;
  if FileName <> '' then
    Result := True;
end;

// -----------------------------------------------------------------------------
// ���]�F�擾

function GetInvertColor(Color: TColor): TColor;
begin
  if Color < 0 then
    Color := GetSysColor(Color and $FF);
  Result := Color xor $FFFFFF;
end;

end.
