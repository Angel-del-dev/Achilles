unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, WMPLib_TLB, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, System.JSON, System.IOUtils, ActiveX,
  Vcl.OleServer, Vcl.FileCtrl, Vcl.Menus, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ExtDlgs, Vcl.WinXCtrls, Vcl.Buttons,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

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
    N2: TMenuItem;
    Removeselected1: TMenuItem;
    lbCurrentPlaylist: TLabel;
    PlaylistsPopup: TPopupMenu;
    Removeallmedia1: TMenuItem;
    View1: TMenuItem;
    togglePlayListButton: TMenuItem;
    MediaplayerConnection: TFDConnection;
    PlaylistsTable: TFDQuery;
    MediaTable: TFDQuery;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MediaListClick(Sender: TObject);
    procedure AddFileClick(Sender: TObject);
    procedure VideoPlayerPlayStateChange(ASender: TObject; NewState: Integer);
    procedure ScanInFolderClick(Sender: TObject);
    procedure OptionsButtonClick(Sender: TObject);
    procedure lbCurrentPlaylistClick(Sender: TObject);
    procedure Removeallmedia1Click(Sender: TObject);
    procedure togglePlayListButtonClick(Sender: TObject);
  private
    { Private declarations }
    function ReadFile(FileRoute:string):string;
    function GetLastSeparatedByDelimiter(Delimiter: Char; Text: string):string;
    procedure FormTree;
    procedure WriteToFile(Route: string; Data: string);
    function SavedListToString():string;
    procedure RecursiveFolderScan(Route: string);
    procedure togglePlayListExecute();
    procedure LoadPlayLists;
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

procedure TForm1.togglePlayListExecute;
begin
    togglePlayListButton.Caption := 'Show Playlist';
    MediaList.Visible := not MediaList.Visible;
    if MediaList.Visible then
      togglePlayListButton.Caption := 'Hide Playlist';
end;

procedure TForm1.togglePlayListButtonClick(Sender: TObject);
begin
    togglePlayListExecute;
end;

procedure TForm1.FormTree;
  var
    FileRoute,
    Name,
    PlayListName: string;
begin
    PlayListName := lbCurrentPlaylist.Caption;
    MediaTable.ParamByName('PLAYLIST').asString := PlayListName;
    MediaTable.Open;
    MediaTable.First;
    while not Mediatable.Eof do
    begin
      MediaList.Items.Add(MediaTable.FieldByName('NAME').Value);
      MediaTable.Next;
    end;

    MediaTable.Close;
end;

procedure TForm1.LoadPlayLists;
  var
    NewItem: TMenuItem;
begin
  PlaylistsTable.First;
  PlaylistsTable.Open;
  lbCurrentPlaylist.Caption := PlaylistsTable.FieldByName('NAME').Value;
  while not PlaylistsTable.Eof do
  begin
    NewItem := TMenuItem.Create(PlaylistsPopup); // Create a new menu item
    NewItem.Caption := PlaylistsTable.FieldByName('NAME').Value;
    {NewItem.OnClick := ;} // Assign an event handler
    PlaylistsPopup.Items.Add(NewItem);
    PlaylistsTable.Next;
  end;
  PlaylistsTable.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadPlayLists;
  FormTree;
  { Add configuration }
  togglePlayListButton.Caption := 'Hide Playlist';
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
        { Change this }
        WriteToFile(DataFile, Format('{"All": [%s]}', [SavedListToString()]));
        FormTree;
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
      {Change this}
      WriteToFile(DataFile, Format('{"All": [%s]}', [SavedListToString()]));
      FormTree;
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
   FormTree;
end;


begin
  SavedFileList := TStringList.Create;
  DataFile := '..\data.json';
end.
