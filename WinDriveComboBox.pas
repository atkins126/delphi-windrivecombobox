unit WinDriveComboBox;

{
Copyright (c) 2008, Shinya Okano<xxshss@yahoo.co.jp>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3. Neither the name of the authors nor the names of its contributors
   may be used to endorse or promote products derived from this
   software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

--
license: New BSD License
web: http://www.bitbucket.org/tokibito/windrivecombobox/overview/
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, ShellAPI,
  Generics.Collections;

type
  TTextCase = (tcLowerCase, tcUpperCase, tcNoneCase);
  TShowCase = (dvSimple, dvWin31, dvWin98);

  TWinDrive = class(TObject)
  private
    FDriveNumber: Integer;
    FID: string;
    FDriveLetter: Char;
    FDriveType: Integer;
    FPathName: string;
    function GetTextWithStyle(ShowCase: TShowCase = dvSimple;
        TextCase: TTextCase = tcNoneCase): string;
    function GetText: string;
  public
    constructor Create(DriveNumber: Integer);
    property ID: string read FID;
    property Text: string read GetText;
    property PathName: string read FPathName;
    property DriveLetter: Char read FDriveLetter;
    property DriveType: Integer read FDriveType;
  end;

  TWinDriveComboBox = class(TCustomComboBox)
  private
    FIconHandles: TObjectDictionary<Integer, TIcon>;
    FWinDrives: TObjectList<TWinDrive>;
    FTextCase: TTextCase;
    FShowCase: TShowCase;
    FOnChange: TNotifyEvent;
  protected
    function GetDrives(Index: Integer): TWinDrive;
    function GetSelected: TWinDrive;
    procedure Loaded; override;
    procedure RefreshItems;
    procedure DrawItem(Index: Integer; Rect: TRect;
        State: TOwnerDrawState); override;
    procedure SetTextcase(Value: TTextCase);
    procedure SetShowcase(Value: TShowCase);
    procedure Change; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DitectDrives;
    function GetCount: Integer; override;
    property Drives[Index: Integer]: TWinDrive read GetDrives;
    property Selected: TWinDrive read GetSelected;
    property Count: Integer read GetCount;
  published
    property TextCase: TTextCase read FTextCase write SetTextCase;
    property ShowCase: TShowCase read FShowCase write SetShowCase;
    property Align;
    property Color;
    property Constraints;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ItemIndex;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDropDown;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnStartDrag;
  end;

procedure Register;

implementation

constructor TWinDrive.Create(DriveNumber: Integer);

  function GetVolumeName(PathName: string): string;
  var
    MaxComponentLength, VolumeFlags: Cardinal;
    VolumeNameBuffer: array [0..255] of Char;
  begin
    if GetVolumeInformation(PChar(PathName), VolumeNameBuffer,
        SizeOf(VolumeNameBuffer), nil, MaxComponentLength, VolumeFlags, nil, 0) then
      Result := VolumeNameBuffer
    else
      Result := '';
  end;

  function GetRemoteVolumeName(DriveLetter: Char): string;
  var
    VolumeNameBuffer: array [0..255] of Char;
    BufferSize: Cardinal;
  begin
    BufferSize := SizeOf(VolumeNameBuffer);
    if WNetGetConnection(PChar(DriveLetter + ':'), VolumeNameBuffer,
        BufferSize) = NO_ERROR then
      Result := VolumeNameBuffer
    else
      Result := '';
  end;
begin
  FDriveNumber := DriveNumber;

  FDriveLetter := Chr(Ord('A') + FDriveNumber);
  FPathName := Format('%s:\', [FDriveLetter]);

  FDriveType := GetDriveType(PChar(FPathName));
  if (FDriveType = DRIVE_REMOVABLE) and (FDriveNumber <= 1) then
    FDriveType := 0; // floppy disk

  case FDriveType of
    0:
      FID := '3.5 インチ FD';
    DRIVE_REMOVABLE:
      begin
        FID := GetVolumeName(FPathName);
        if FID = '' then
          FID := 'リムーバブル ディスク';
      end;
    DRIVE_FIXED:
      begin
        FID := GetVolumeName(FPathName);
        if FID = '' then
          FID := 'ローカル ディスク';
      end;
    DRIVE_REMOTE:
      begin
        FID := GetRemoteVolumeName(FDriveLetter);
        if FID = '' then
          FID := 'ネットワーク ドライブ';
      end;
    DRIVE_CDROM:
      begin
        FID := GetVolumeName(FPathName);
        if FID = '' then
          FID := 'CD-ROM ドライブ';
      end;
    DRIVE_RAMDISK:
      FID := 'RAM ディスク';
    else
      FID := ' ';
  end;
end;

function TWinDrive.GetTextWithStyle(ShowCase: TShowCase = dvSimple;
    TextCase: TTextCase = tcNoneCase): string;
begin
  case ShowCase of
    dvSimple:
      Result := Format('(%s:)', [FDriveLetter]);
    dvWin31:
      Result := Format('(%s:) [%s]', [FDriveLetter, FID]);
    dvWin98:
      Result := Format('%s (%s:)', [FID, FDriveLetter]);
  end;
  case TextCase of
    tcLowerCase:
      Result := LowerCase(Result);
    tcUpperCase:
      Result := UpperCase(Result);
  end;
end;

function TWinDrive.GetText: string;
begin
  Result := GetTextWithStyle;
end;

constructor TWinDriveComboBox.Create(AOwner: TComponent);
var
  ResourceDLLName: string;

  function IsVista: Boolean;
  var
    VersionInfo: TOSVersionInfo;
  begin
    VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    if GetVersionEx(VersionInfo) then
      Result := (VersionInfo.dwMajorVersion = 6)
    else
      Result := False;
  end;

  procedure LoadIconToDict(DLLName: string; Key: Integer; IconIndex: Integer);
  var
    phIconLarge, phIconSmall: HICON;
  begin
    FIconHandles.Add(Key, TIcon.Create);
    ExtractIconEx(PChar(DLLName), IconIndex, phIconLarge, phIconSmall, 1);
    FIconHandles[Key].Handle := phIconSmall;
    // destroy large icon
    DestroyIcon(phIconLarge);
  end;

begin
  inherited Create(AOwner);
  Style := csOwnerDrawFixed;
  FShowCase := dvWin98;
  FTextCase := tcNoneCase;

  // load shell icons
  FIconHandles := TObjectDictionary<Integer, TIcon>.Create;
  if IsVista then
  begin
    ResourceDLLName := 'imageres.dll';
    LoadIconToDict(ResourceDLLName, 0, 22); // Floppy disk
    LoadIconToDict(ResourceDLLName, DRIVE_REMOVABLE, 29);
    LoadIconToDict(ResourceDLLName, DRIVE_FIXED, 26);
    LoadIconToDict(ResourceDLLName, DRIVE_REMOTE, 27);
    LoadIconToDict(ResourceDLLName, DRIVE_CDROM, 24);
    LoadIconToDict(ResourceDLLName, DRIVE_RAMDISK, 33);
  end
  else
  begin
    ResourceDLLName := 'shell32.dll';
    LoadIconToDict(ResourceDLLName, 0, 6); // Floppy disk
    LoadIconToDict(ResourceDLLName, DRIVE_REMOVABLE, 7);
    LoadIconToDict(ResourceDLLName, DRIVE_FIXED, 8);
    LoadIconToDict(ResourceDLLName, DRIVE_REMOTE, 9);
    LoadIconToDict(ResourceDLLName, DRIVE_CDROM, 11);
    LoadIconToDict(ResourceDLLName, DRIVE_RAMDISK, 7);
  end;

  // create the drive list
  FWinDrives := TObjectList<TWinDrive>.Create;
end;

destructor TWinDriveComboBox.Destroy;
begin
  FreeAndNil(FWinDrives);
  FreeAndNil(FIconHandles);
  inherited;
end;

procedure TWinDriveComboBox.Loaded;
begin
  inherited;
  DitectDrives;
  ItemIndex := 0;
end;

procedure TWinDriveComboBox.RefreshItems;
var
  I, Index: Integer;
begin
  Index := ItemIndex;
  Items.Clear;
  for I := 0 to FWinDrives.Count - 1 do
    Items.Add(FWinDrives[i].GetTextWithStyle(FShowCase, FTextCase));
  ItemIndex := Index;
end;

procedure TWinDriveComboBox.DitectDrives;
var
  I: Integer;
  Drives: Cardinal;
  DriveBits: set of 0..25;
  Drive: TWinDrive;
begin
  FWinDrives.Clear;

  Drives := GetLogicalDrives;
  if Drives <> 0 then
  begin
    Cardinal(DriveBits) := Drives;
    for I := 0 to 25 do
      if I in DriveBits then
      begin
        Drive := TWinDrive.Create(I);
        FWinDrives.Add(Drive);
      end;
  end;

  RefreshItems;
end;

function TWinDriveComboBox.GetDrives(Index: Integer): TWinDrive;
begin
  Result := FWinDrives[Index];
end;

function TWinDriveComboBox.GetCount: Integer;
begin
  Result := FWinDrives.Count;
end;

function TWinDriveComboBox.GetSelected: TWinDrive;
begin
  Result := GetDrives(ItemIndex);
end;

procedure TWinDriveComboBox.DrawItem(Index: Integer; Rect: TRect;
    State: TOwnerDrawState);
const
  ICON_WIDTH = 16;
  ICON_HEIGHT = 16;
begin
  if Index > Items.Count - 1 then Exit;

  with Canvas do
  begin
    FillRect(Rect);
    DrawIconEx(Handle, Rect.Left + 2,
        (Rect.Top + Rect.Bottom - ICON_HEIGHT) div 2,
        FIconHandles[FWinDrives[Index].DriveType].Handle,
        ICON_WIDTH, ICON_HEIGHT,
        0, 0, DI_NORMAL);
    Rect.Left := Rect.Left + ICON_WIDTH + 6;
    DrawText(Handle, PChar(Items[Index]), (-1), Rect,
        DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX);
  end;
end;

procedure TWinDriveComboBox.SetTextCase(Value: TTextCase);
begin
  FTextCase := Value;
  RefreshItems;
end;

procedure TWinDriveComboBox.SetShowCase(Value: TShowCase);
begin
  FShowCase := Value;
  RefreshItems;
end;

procedure TWinDriveComboBox.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure Register;
begin
  RegisterComponents('nullpobug', [TWinDriveComboBox]);
end;

end.
