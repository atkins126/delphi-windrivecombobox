unit WinDriveComboBox;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, ShellAPI,
  Generics.Collections;

type
  TTextCase = (tcLowerCase, tcUpperCase);
  TShowCase = (dvSimple, dvWin31, dvWin98);

  TWinDrive = record
    DriveLetter: Char;
    DriveType: Integer;
    Text: string;
  end;

  TWinDriveComboBox = class(TCustomComboBox)
  private
    FIconHandles: TObjectDictionary<Integer, TIcon>;
    FWinDrives: TList<TWinDrive>;
    FTextCase: TTextCase;
    FShowCase: TShowCase;
  protected
    function GetDrives(Index: Integer): TWinDrive;
    function GetSelected: TWinDrive;
    procedure Loaded; override;
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
  published
    property TextCase: TTextCase read FTextCase write SetTextCase;
    property ShowCase: TShowCase read FShowCase write SetShowCase;
    property Align;
    property Color;
    property Constraints;
    property Count: Integer read GetCount;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property Selected: TWinDrive read GetSelected;
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

  // load icons
  FIconHandles := TObjectDictionary<Integer, TIcon>.Create;
  LoadIconToDict(0, 6); // Floppy disk
  LoadIconToDict(DRIVE_REMOVABLE, 7);
  LoadIconToDict(DRIVE_FIXED, 8);
  LoadIconToDict(DRIVE_REMOTE, 9);
  LoadIconToDict(DRIVE_CDROM, 11);
  LoadIconToDict(DRIVE_RAMDISK, 7);

  // create drive list
  FWinDrives := TList<TWinDrive>.Create;
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

procedure TWinDriveComboBox.DitectDrives;
var
  I: Integer;
  Drives: Cardinal;
  DriveBits: set of 0..25;
  Drive: TWinDrive;
begin
  Items.Clear;
  FWinDrives.Clear;

  Drives := GetLogicalDrives;
  if Drives <> 0 then
  begin
    Cardinal(DriveBits) := Drives;
    for I := 0 to 25 do
      if I in DriveBits then
      begin
        Drive.DriveLetter := Chr(Ord('A') + I);
        Drive.Text := Drive.DriveLetter + ':\';
        Drive.DriveType := GetDriveType(PChar(Drive.Text));
        if (Drive.DriveType = DRIVE_REMOVABLE) and (I <= 1) then
          Drive.DriveType := 0;
        FWinDrives.Add(Drive);
        Items.Add(Drive.Text);
      end;
  end;
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

procedure TWinDriveComboBox.SetTextcase(Value: TTextCase);
begin
  //
end;

procedure TWinDriveComboBox.SetShowcase(Value: TShowCase);
begin
  //
end;

procedure Register;
begin
  RegisterComponents('nullpobug', [TWinDriveComboBox]);
end;

end.
