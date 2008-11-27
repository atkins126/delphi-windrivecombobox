unit WinDriveComboBox;

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
  protected
    function GetDrives(Index: Integer): TWinDrive;
    function GetSelected: TWinDrive;
    procedure Loaded; override;
    procedure RefreshItems;
    procedure DrawItem(Index: Integer; Rect: TRect;
        State: TOwnerDrawState); override;
    procedure SetTextcase(Value: TTextCase);
    procedure SetShowcase(Value: TShowCase);
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
    if GetVolumeInformation(PWideChar(PathName), VolumeNameBuffer,
        SizeOf(VolumeNameBuffer), nil, MaxComponentLength, VolumeFlags, nil, 0) then
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
        FID := '';
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

  procedure LoadIconToDict(Key: Integer; IconIndex: Integer);
  var
    phIconLarge, phIconSmall: HICON;
  begin
    FIconHandles.Add(Key, TIcon.Create);
    ExtractIconEx('shell32.dll', IconIndex, phIconLarge, phIconSmall, 1);
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
  LoadIconToDict(0, 6); // Floppy disk
  LoadIconToDict(DRIVE_REMOVABLE, 7);
  LoadIconToDict(DRIVE_FIXED, 8);
  LoadIconToDict(DRIVE_REMOTE, 9);
  LoadIconToDict(DRIVE_CDROM, 11);
  LoadIconToDict(DRIVE_RAMDISK, 7);

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

procedure Register;
begin
  RegisterComponents('nullpobug', [TWinDriveComboBox]);
end;

end.
