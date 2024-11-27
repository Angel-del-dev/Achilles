unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, WMPLib_TLB, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, System.JSON, System.IOUtils, ActiveX,
  Vcl.OleServer, Vcl.FileCtrl, Vcl.Menus, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ExtDlgs, Vcl.WinXCtrls, Vcl.Buttons;

type
  TForm1 = class(TForm)
    VideoPlayer: TWindowsMediaPlayer;
    ControlsPanel: TPanel;
    MediaList: TListBox;
    Loader: TPanel;
    Label1: TLabel;
    FoundLabel: TLabel;
    MainToolBar: TToolBar;
    OptionsButton: TSpeedButton;
    OptionsPopupButton: TPopupMenu;
    Addfile1: TMenuItem;
    Addmedia1: TMenuItem;
    Addallmediafromfolder1: TMenuItem;
    N1: TMenuItem;
    Createplaylist1: TMenuItem;
    Removeplaylist1: TMenuItem;
    Rename1: TMenuItem;
    Modes1: TMenuItem;
    Playlisteditor1: TMenuItem;
    N2: TMenuItem;
    Removeselected1: TMenuItem;
    lbCurrentPlaylist: TLabel;
    PlaylistsPopup: TPopupMenu;
    Removeallmedia1: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MediaListClick(Sender: TObject);
    procedure AddFileClick(Sender: TObject);
    procedure VideoPlayerPlayStateChange(ASender: TObject; NewState: Integer);
    procedure ScanInFolderClick(Sender: TObject);
    procedure OptionsButtonClick(Sender: TObject);
    procedure lbCurrentPlaylistClick(Sender: TObject);
    procedure Removeallmedia1Click(Sender: TObject);
  private
    { Private declarations }
    function ReadFile(FileRoute:string):string;
    function GetLastSeparatedByDelimiter(Delimiter: Char; Text: string):string;
    procedure ParseAndFormTree(FileRoute: string);
    procedure FormTree(Configuration: TJSONObject);
    procedure WriteToFile(Route: string; Data: string);
    function SavedListToString():string;
    procedure RecursiveFolderScan(Route: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

var
  SavedFileList: TStringList;
  DataFile: string;

{$R *.dfm}

{ Utils }
function TForm1.ReadFile(FileRoute : string):string;
  var
    Text: TextFile;
    line,
    AllText: string;
begin
     AllText := '';
     AssignFile(Text, FileRoute);
     Reset(Text);
     while not Eof(Text) do
     begin
      Readln(Text, line);
      AllText := AllText + line;
     end;
     CloseFile(Text);
     result := AllText;
end;

function TForm1.GetLastSeparatedByDelimiter(Delimiter: Char; Text: string):string;
  var
    StringList: TStringList;
begin
  StringList := TStringList.Create;
  StringList.Delimiter := Delimiter;
  StringList.StrictDelimiter := True;
  StringList.DelimitedText := Text;

  result := StringList.Strings[StringList.Count - 1];
end;

procedure TForm1.WriteToFile(Route: string; Data: string);
  var
    LogFile: TextFile;
begin
  AssignFile(LogFile, Route);
  Rewrite(LogFile);
  WriteLn(LogFile, Data);
  CloseFile(LogFile);
end;

function Tform1.SavedListToString():string;
  var
    I: integer;
begin
  Result := '';
  for I := 0 to SavedFileList.Count - 1 do
  begin
    Result := Result + '"'+ StringReplace(SavedFileList[i], '\', '\\', [rfReplaceAll])+ '",'
  end;
  Result := Copy(Result, 0, Result.Length - 1)
end;

{ Actions }

procedure TForm1.VideoPlayerPlayStateChange(ASender: TObject;
  NewState: Integer);
begin
  { 1 = Media stoped }
  if NewState = 1 then
  begin
      VideoPlayer.URL := '';
  end;
  { 3 = Media loaded }
  if NewState = 3 then
  begin
      Loader.Visible := False;
      Loader.SendToBack;
  end;
end;


procedure TForm1.MediaListClick(Sender: TObject);
  var
    SelectedItem: integer;
begin
   SelectedItem := MediaList.ItemIndex;
   if SelectedItem >= 0 then
   begin
      VideoPlayer.URL := SavedFileList.Strings[SelectedItem];
      Loader.BringToFront;
      Loader.Visible := True;
   end;
end;

procedure TForm1.FormTree(Configuration: TJSONObject);
  var
    FileRoute: string;
    I: integer;
    Route: string;
    Pair: TJSONPair;
    NewItem: TMenuItem;
    JsonArray: TJSONArray;
begin
    for Pair in Configuration do
    begin
        NewItem := TMenuItem.Create(PlaylistsPopup); // Create a new menu item
        NewItem.Caption := Pair.JsonString.Value;
        {NewItem.OnClick := ; // Assign an event handler   }
        lbCurrentPlaylist.PopupMenu.Items.Add(NewItem);
        JsonArray := (Pair.JsonValue as TJSONArray);
        for I := 0 to JsonArray.Count -1 do
        begin
            Route := JsonArray.Get(I).Value;
            MediaList.Items.Add(GetLastSeparatedByDelimiter('\', Route));
            SavedFileList.Add(Route);
        end;
    end;
end;

procedure TForm1.ParseAndFormTree(FileRoute: string);
  var
    FileContents: string;
    JSONObject: TJSONObject;
    JSONArray: TJSONArray;
begin
  MediaList.Clear;
  SavedFileList.Clear;
  FileContents := ReadFile(FileRoute);
  JSONObject := TJSONObject.ParseJSONValue(FileContents) as TJSONObject;
  if JSONObject <> nil then
  begin
    if not JSONObject.TryGetValue('All', JSONArray) then
      showMessage('Data file is corrupted')
    else
    begin
      FormTree(JSONObject);
    end;
    
  end;
  JSONObject.Free;
end;


procedure TForm1.FormCreate(Sender: TObject);
  var
    StringList: TStringList;
begin
  { Creating the default file if it doesn't exists(Its the first time executing the application) }
  if not FileExists(DataFile) then
  begin
    StringList := TStringList.Create;
    try
        StringList.Add('{"All": []}');
        StringList.SaveToFile(DataFile);
    finally
      StringList.Free;
    end;
  end;
  ParseAndFormTree(DataFile);
end;

procedure TForm1.AddFileClick(Sender: TObject);
  var
    openDialog: TOpenDialog;
begin
  openDialog := TOpenDialog.Create(nil);
  try
    openDialog.InitialDir := '';
    openDialog.Filter := 'Video Files (*.mp4;*.avi;*.mov;*.wmv;*.mkv)';
    openDialog.Options := [ofFileMustExist];
    if openDialog.Execute then
    begin
      if SavedFileList.IndexOf(openDialog.FileName) < 0 then
      begin
        SavedFileList.Add(openDialog.FileName);
        WriteToFile(DataFile, Format('{"All": [%s]}', [SavedListToString()]));
        ParseAndFormTree(DataFile);
      end;
    end;
    
  finally
    openDialog.Free;
  end;
end;

procedure TForm1.RecursiveFolderScan(Route: string);
  var
    Mask,
    FileName: string;
    FileList: TArray<string>;
    Masks: array of string;
begin
    SetLength(Masks, 2);
    Masks[0] := '*.mp4'; Masks[1] := '*.mkv';

    for Mask in Masks do
    begin
        FileList := TDirectory.GetFiles(Route, Mask, TSearchOption.soAllDirectories);
        for FileName in FileList do
        begin
          if SavedFileList.IndexOf(FileName) >= 0 then
            continue;
          SavedFileList.Add(FileName);
        end;
    end;
end;



procedure TForm1.ScanInFolderClick(Sender: TObject);
  var
    Directory: string;
begin
    if SelectDirectory('Select a folder', '', Directory) then
    begin
      RecursiveFolderScan(Directory);
      WriteToFile(DataFile, Format('{"All": [%s]}', [SavedListToString()]));
      ParseAndFormTree(DataFile);
    end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  VideoPlayer.Free;
  SavedFileList.Free;
end;

procedure TForm1.OptionsButtonClick(Sender: TObject);
  var Point: TPoint;
begin
  GetCursorPos(Point);
  OptionsPopupButton.Popup(Point.x, Point.y);
end;

procedure TForm1.lbCurrentPlaylistClick(Sender: TObject);
 var Point: TPoint;
begin
  GetCursorPos(Point);
  lbCurrentPlaylist.PopupMenu.Popup(Point.x, Point.y);
end;

procedure TForm1.Removeallmedia1Click(Sender: TObject);
begin
   SavedFileList.Clear;
   WriteToFile(DataFile, Format('{"All": [%s]}', [SavedListToString()]));
   ParseAndFormTree(DataFile);
end;


begin
  SavedFileList := TStringList.Create;
  DataFile := '..\data.json';
end.
