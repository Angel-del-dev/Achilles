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
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Data.DbxSqlite, Data.SqlExpr;

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
    N2: TMenuItem;
    Removeselected1: TMenuItem;
    lbCurrentPlaylist: TLabel;
    PlaylistsPopup: TPopupMenu;
    Removeallmedia1: TMenuItem;
    View1: TMenuItem;
    togglePlayListButton: TMenuItem;
    CopySelectedMediaPopup: TMenuItem;
    PlayListConfiguration: TPanel;
    playListNameConfig: TSearchBox;
    playListControlsText: TStaticText;
    confirmButton: TButton;
    cancelButton: TButton;
    MediaplayerConnection: TFDConnection;
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
    procedure Removeselected1Click(Sender: TObject);
    procedure Createplaylist1Click(Sender: TObject);
    procedure cancelButtonClick(Sender: TObject);
    procedure confirmButtonClick(Sender: TObject);
    procedure Removeplaylist1Click(Sender: TObject);
  private
    { Private declarations }
    function ReadFile(FileRoute:string):string;
    function GetLastSeparatedByDelimiter(Delimiter: Char; Text: string):string;
    procedure FormTree;
    procedure WriteToFile(Route: string; Data: string);
    procedure RecursiveFolderScan(Route: string);
    procedure togglePlayListExecute(Update: Boolean = True);
    procedure LoadPlayLists;
    function Query(QueryString: String):TFDQuery;
    procedure ChangePlayList(Sender: TObject);
    procedure SaveMedia(Route: String);
    procedure MoveToPlayList(Sender: TObject);
    procedure PlaylistAction;
    function GetBooleanConfiguration(KeyName: String): Boolean;
    procedure SetBooleanConfiguration(KeyName: String; Value: Boolean);
    procedure DBConnect;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

var
  CurrentPlayListMedia: TStringList;
  MediaplayerConnection: TFDConnection;

{$R *.dfm}

{ Utils }

function TForm1.GetBooleanConfiguration(KeyName: String): Boolean;
  var
    QueryObj: TFDQuery;
begin
  QueryObj := Query('SELECT VALUE FROM BOOLEANCONFIGURATION WHERE KEYNAME = :KEYNAME');
  QueryObj.Params.ParamByName('KEYNAME').Value := KeyName;
  QueryObj.open;
  result := QueryObj.FieldByName('VALUE').asBoolean;
  QueryObj.close;
  QueryObj.Free;
  
end;

procedure TForm1.SetBooleanConfiguration(KeyName: String; Value: Boolean);
  var
    QueryObj: TFDQuery;
begin
  QueryObj := Query('UPDATE BOOLEANCONFIGURATION SET VALUE = :VALUE WHERE KEYNAME = :KEYNAME');
  QueryObj.Params.ParamByName('VALUE').Value := Value;
  QueryObj.Params.ParamByName('KEYNAME').Value := KeyName;
  QueryObj.execSQL;
  QueryObj.Free;
  
end;

function TForm1.Query(QueryString: String):TFDQuery;
  var
    QueryObj: TFDQuery;
begin
   QueryObj := TFDQuery.Create(nil);
   QueryObj.Connection := MediaplayerConnection;

   QueryObj.SQL.Text := QueryString;
   result := QueryObj;
end;

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

procedure TForm1.DBConnect;
  var 
    StringList: TStringList;
begin

  MediaplayerConnection := TFDConnection.Create(nil);

  StringList := TStringList.Create;
  StringList.Delimiter := '\';
  StringList.StrictDelimiter := True;
  StringList.DelimitedText := ExtractFilePath(ParamStr(0));
  StringList.Delete(StringList.Count - 1);

  MediaList.Items.Add(StringList.DelimitedText+'\video_player.sdb');
  
  try
    MediaplayerConnection.DriverName := 'SQLite';
    MediaplayerConnection.Params.Database :=  StringList.DelimitedText+'\video_player.sdb';
    MediaplayerConnection.ConnectionName := 'Video_player';
    MediaplayerConnection.Open;
    
    MediaplayerConnection.Connected := True;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
//                         ExtractFilePath(ParamStr(0)+'\..\video_player.sdb')
//  MediaplayerConnection.Params.Database := ExtractFilePath(StringList.DelimitedText+'\video_player.sdb');
//  MediaplayerConnection.Connected := True;
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
      VideoPlayer.URL := CurrentPlayListMedia.Strings[SelectedItem];
      Loader.BringToFront;
      Loader.Visible := True;
   end;
end;

procedure TForm1.togglePlayListExecute(Update: Boolean = True);
  var
    ShowPlayList: Boolean;
begin
    ShowPlayList := GetBooleanConfiguration('SHOW_PLAYLIST_BY_DEFAULT');
    if Update then
    begin
      SetBooleanConfiguration('SHOW_PLAYLIST_BY_DEFAULT', not ShowPlayList);
    end;

    ShowPlayList := GetBooleanConfiguration('SHOW_PLAYLIST_BY_DEFAULT');
      
    togglePlayListButton.Caption := 'Hide Playlist';
    MediaList.Visible := ShowPlayList;
    if ShowPlayList then
      togglePlayListButton.Caption := 'Show Playlist';
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
    QueryObj: TFDQuery;
begin
    MediaList.Items.Clear;
    CurrentPlayListMedia.Clear;

    PlayListName := lbCurrentPlaylist.Caption;
    QueryObj := Query('SELECT NAME, ROUTE FROM MEDIA WHERE PLAYLIST = :PLAYLIST ');
    QueryObj.Params.ParamByName('PLAYLIST').asString := PlayListName;
    QueryObj.Open;

    QueryObj.First;
    while not QueryObj.Eof do
    begin
      MediaList.Items.Add(QueryObj.FieldByName('NAME').Value);
      CurrentPlayListMedia.Add(QueryObj.FieldByName('ROUTE').Value);
      QueryObj.Next;
    end;

    QueryObj.Close;
    QueryObj.Free;
end;

procedure TForm1.LoadPlayLists;
  var
    NewItem: TMenuItem;
    QueryObj : TFDQuery;
begin
  PlaylistsPopup.Items.Clear;
    QueryObj := Query('SELECT NAME FROM PLAYLISTS');
    QueryObj.Open;
    lbCurrentPlaylist.Caption := QueryObj.FieldByName('NAME').Value;
    while not QueryObj.Eof do
    begin
      { PlayListSelector item } 
      NewItem := TMenuItem.Create(PlaylistsPopup);
      NewItem.Caption := QueryObj.FieldByName('NAME').Value;
      NewItem.OnClick := ChangePlayList;
      PlaylistsPopup.Items.Add(NewItem);

      { Copy to PlayList item }
      NewItem := TMenuItem.Create(CopySelectedMediaPopup);
      NewItem.Caption := QueryObj.FieldByName('NAME').Value;
      NewItem.OnClick := MoveToPlayList;  
      CopySelectedMediaPopup.Add(NewItem);   
      QueryObj.Next;
    end;


    QueryObj.Close;
    QueryObj.Free;
end;

procedure TForm1.MoveToPlayList(Sender: TObject);
  var
    MenuItem : TMenuItem;
    Index: Integer;
    FileName,
    NewPlayList: String;
    QueryObj: TFDQuery;
    IsPresent: Boolean;
begin
  Index := MediaList.ItemIndex;
  FileName := MediaList.Items[Index];
  
  if Index < 0 then
  begin
    ShowMessage('No item was selected');
    exit;
  end;

  if Sender is TMenuItem then
  begin
    MenuItem := TMenuItem(Sender);
    Index := CopySelectedMediaPopup.IndexOf(MenuItem);
    NewPlayList := StringReplace(CopySelectedMediaPopup.Items[Index].Caption, '&', '', [rfReplaceAll]);

    QueryObj := Query('SELECT 1 FROM MEDIA WHERE NAME = :NAME AND PLAYLIST = :PLAYLIST');
    QueryObj.Params.ParamByName('NAME').Value := FileName;
    QueryObj.Params.ParamByName('PLAYLIST').Value := NewPlayList;
    QueryObj.Open;
    IsPresent := QueryObj.RecordCount > 0;
    QueryObj.Close;
    QueryObj.Free;
    
    if IsPresent then
    begin
      ShowMessage('The selected media is already in the requested playlist');
      exit;
    end;

    QueryObj := Query(
    ' INSERT INTO MEDIA (NAME, PLAYLIST, ROUTE) '+
    ' SELECT NAME, :NEWPLAYLIST, ROUTE '+
    ' FROM MEDIA '+
    ' WHERE NAME = :NAME AND PLAYLIST = :CURRENTPLAYLIST '
    );
    
    QueryObj.Params.ParamByName('NAME').Value := FileName;
    QueryObj.Params.ParamByName('CURRENTPLAYLIST').Value := lbCurrentPlaylist.Caption;
    QueryObj.Params.ParamByName('NEWPLAYLIST').Value := NewPlayList;
    QueryObj.execSQL;
    QueryObj.Free;
  end;
end;

procedure TForm1.ChangePlayList(Sender: TObject);
  var
    MenuItem: TMenuItem;
    Index: Integer;
begin
  if Sender is TMenuItem then
  begin
    MenuItem := TMenuItem(Sender);
    Index := PlaylistsPopup.Items.IndexOf(MenuItem);
    lbCurrentPlaylist.Caption := StringReplace(PlayListsPopup.Items[Index].Caption, '&', '', [rfReplaceAll]);
    FormTree;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DBConnect;
  LoadPlayLists;
  FormTree;
  
  togglePlayListExecute(False);  
end;

procedure TForm1.SaveMedia(Route: String);
  var
    FileName: String;
    QueryObj: TFDQuery;
    IsRepeated: Boolean;
begin
  FileName := GetLastSeparatedByDelimiter('\', Route);
  if CurrentPlayListMedia.IndexOf(Route) >= 0 then
    exit;

  QueryObj := Query('INSERT INTO MEDIA(NAME, PLAYLIST, ROUTE) VALUES (:NAME, :PLAYLIST, :ROUTE)');
  QueryObj.ParamByName('PLAYLIST').Value := lbCurrentPlaylist.Caption;
  QueryObj.ParamByName('NAME').Value := FileName;
  QueryObj.ParamByName('ROUTE').Value := Route;
  QueryObj.execSQL;
  QueryObj.Free;
end;

procedure TForm1.AddFileClick(Sender: TObject);
  var
    openDialog: TOpenDialog;
    QueryObj: TFDQuery;
    FileName: String;
    IsRepeated: Boolean;
begin
  openDialog := TOpenDialog.Create(nil);
  try
    openDialog.InitialDir := '';
    openDialog.Filter := 'Video Files (*.mp4;*.avi;*.mov;*.wmv;*.mkv)';
    openDialog.Options := [ofFileMustExist];
    if openDialog.Execute then
    begin
        SaveMedia(openDialog.FileName);
        FormTree;
    end;

  finally
    openDialog.Free;
  end;
end;

procedure TForm1.RecursiveFolderScan(Route: string);
  var
    Mask,
    FileName,
    FoundRoute: string;
    FileList: TArray<string>;
    Masks: array of string;
begin
    SetLength(Masks, 2);
    Masks[0] := '*.mp4'; Masks[1] := '*.mkv';

    for Mask in Masks do
    begin
        FileList := TDirectory.GetFiles(Route, Mask, TSearchOption.soAllDirectories);
        for FoundRoute in FileList do
        begin
          SaveMedia(FoundRoute);
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
      FormTree;
    end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  VideoPlayer.Free;
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
  var
    QueryObj : TFDQuery;
begin
    QueryObj := Query('DELETE FROM MEDIA WHERE PLAYLIST = :PLAYLIST');
    QueryObj.ParamByName('PLAYLIST').asString := lbCurrentPlaylist.Caption;
    QueryObj.ExecSQL;
    QueryObj.Free;
   FormTree;
end;

procedure TForm1.Removeselected1Click(Sender: TObject);
  var
    ItemIndex: Integer;
    QueryObj: TFDQuery;
begin
  ItemIndex := MediaList.ItemIndex;
  if ItemIndex < 0 then
  begin
    ShowMessage('No item was selected');
    exit;
  end;
  QueryObj := Query('DELETE FROM MEDIA WHERE NAME = :NAME AND PLAYLIST = :PLAYLIST');
  QueryObj.Params.ParamByName('NAME').Value := MediaList.Items[ItemIndex];
  QueryObj.Params.ParamByName('PLAYLIST').Value := lbCurrentPlaylist.Caption;
  QueryObj.execSQL;
  QueryObj.Free;
  FormTree;
end;

procedure TForm1.PlaylistAction;
  var
    QueryObj: TFDQuery;
    IsPresent: Boolean;
begin     
     QueryObj := Query('SELECT 1 FROM PLAYLISTS WHERE NAME = :NAME');
     QueryObj.Params.ParamByName('NAME').Value := playListNameConfig.Text;
     QueryObj.Open;
     IsPresent := QueryObj.RecordCount > 0;
     QueryObj.Close;
     QueryObj.Free;

    if IsPresent then
    begin
      ShowMessage('A playlist with the exact name already exits');
      exit;
    end;
   
    QueryObj := Query('INSERT INTO PLAYLISTS(NAME) VALUES (:NAME)');
    QueryObj.Params.ParamByName('NAME').Value := playListNameConfig.Text;
    QueryObj.execSQL;
    QueryObj.Free;
     
    PlayListConfiguration.Visible := False;
    playListNameConfig.Text := '';
    LoadPlayLists;
    FormTree;  
end;

procedure TForm1.Createplaylist1Click(Sender: TObject);
begin
  playListControlsText.Caption := 'A name must be provided for the new playlist';
  PlayListConfiguration.Visible := True;
  playListNameConfig.SetFocus;
end;

procedure TForm1.cancelButtonClick(Sender: TObject);
begin
  PlayListConfiguration.Visible := False;
  playListNameConfig.Text := '';
end;

procedure TForm1.confirmButtonClick(Sender: TObject);
begin
  PlaylistAction;
  PlayListConfiguration.Visible := False;
  playListNameConfig.Text := '';
end;

procedure TForm1.Removeplaylist1Click(Sender: TObject);
  var 
    QueryObj: TFDQuery;
    IsLastPlayList: Boolean;
begin
   QueryObj := Query('SELECT 1 FROM PLAYLISTS');
   QueryObj.open;
   IsLastPlayList := QueryObj.RecordCount = 1;
   QueryObj.close;
   QueryObj.Free;

   if IsLastPlayList then
   begin
     ShowMessage('A playlist cannot be removed if its the only one');
     exit;
   end;

  QueryObj := Query('DELETE FROM MEDIA WHERE PLAYLIST = :PLAYLIST');
  QueryObj.Params.ParamByName('PLAYLIST').Value := lbCurrentPlaylist.Caption;
  QueryObj.execSQL;
  QueryObj.Free;

  QueryObj := Query('DELETE FROM PLAYLISTS WHERE NAME = :NAME');
  QueryObj.Params.ParamByName('NAME').Value := lbCurrentPlaylist.Caption;
  QueryObj.execSQL;
  QueryObj.Free;
  LoadPlayLists;
  FormTree; 
end;

begin
 CurrentPlayListMedia := TStringList.Create;
end.
