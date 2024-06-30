unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  U2048;

type

  { TBlockPanel }

  TBlockPanel = class(TPanel)
  private
    FValue: Integer;
    procedure SetValue(AValue: Integer);
  public
    constructor Create(TheOwner: TComponent); override;
    property Value: Integer read FValue write SetValue;
  end;

  { TBoardPanel }

  TBoardPanel = class(TPanel)
  private
    FSize: Integer;
    FBlocks: array of array of TBlockPanel;
    procedure Render;
    procedure DrawBlocks;
  public
    constructor Create(TheOwner: TComponent; Board: T2048Board); overload;
  end;


  { TForm1 }

  TForm1 = class(TForm)
    Button5: TButton;
    Button6: TButton;
    LScore: TLabel;
    Memo: TMemo;
    Memo1: TMemo;
    Panel1: TPanel;
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FBoard: T2048Board;
    FBoardPanel: TBoardPanel;
    procedure SetBoard(AValue: T2048Board);
    procedure Render;
  public
    procedure BoardNewBlock(Row, Col: Integer; Value: Integer);
    procedure BoardMove(Direction: TDirection; ValidMovement: boolean);
    procedure BoardGameOver;
    property Board: T2048Board read FBoard write SetBoard;
  end;

var
  Form1: TForm1;

implementation

uses
  Math, StrUtils, LCLIntf;

{$R *.lfm}

{ TBlockPanel }

procedure TBlockPanel.SetValue(AValue: Integer);
begin
  FValue := AValue;

  case AValue of
    0 : Self.Color := clSilver;
    1 : Self.Color := Rgb(252, 243, 207); //2
    2 : Self.Color := Rgb(249, 231, 159); //4
    3 : Self.Color := Rgb(248, 199, 113); //8
    4 : Self.Color := Rgb(243, 156, 18); //16
    5 : Self.Color := Rgb(202, 111, 30); //32
    6 : Self.Color := Rgb(184, 149, 11); //64
    7 : Self.Color := Rgb(184, 149, 11); //128
    8 : Self.Color := Rgb(184, 149, 11); //256
    9 : Self.Color := Rgb(184, 149, 11); //512
    10 : Self.Color := Rgb(184, 149, 11); //1024
    11 : Self.Color := Rgb(184, 149, 11); //2048
  else ;
    Self.Color := clWhite;
  end;

  Caption := '';
  if AValue = 0 then
    Exit;

  Caption := Math.Power(2, AValue).ToString;
end;

constructor TBlockPanel.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Self.Font.Style := [fsBold];
  Self.Font.Size := 16;
end;

{ TBoardPanel }

procedure TBoardPanel.Render;
begin

end;

procedure TBoardPanel.DrawBlocks;
var
  I, J: Integer;
begin
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
    begin
      FBlocks[I][J].Top := I * (Self.Height div FSize);
      FBlocks[I][J].Left := J * (Self.Width div FSize);
      FBlocks[I][J].Height := Self.Height div FSize;
      FBlocks[I][J].Width := Self.Width div FSize;
    end;
end;

constructor TBoardPanel.Create(TheOwner: TComponent; Board: T2048Board);
var
  I, J: Integer;
begin
  inherited Create(TheOwner);
  FSize := Board.Size;
  SetLength(FBlocks, FSize, FSize);
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
    begin
      FBlocks[I][J] := TBlockPanel.Create(Self);
      FBlocks[I][J].Parent := Self;
    end;
end;

procedure TForm1.BoardNewBlock(Row, Col: Integer; Value: Integer);
begin
  Memo1.Lines.Add(
    'NOVO BLOCO: ['+Row.ToString+','+Col.ToString+']: '+Value.ToString+''
  );
end;

procedure TForm1.BoardMove(Direction: TDirection; ValidMovement: boolean);
begin
  Memo1.Lines.Add('moveu: ' + IfThen(ValidMovement, 'Valido', 'Invalido'));
end;

procedure TForm1.BoardGameOver;
begin
  //
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FBoard := T2048Board.Create(4);
  FBoard.OnNewBlock := @BoardNewBlock;
  FBoard.OnMove := @BoardMove;
  FBoard.OnGameOver := @BoardGameOver;

  FBoardPanel := TBoardPanel.Create(Self, FBoard);
  FBoardPanel.Parent := Self;
  FBoardPanel.Top := 48;
  FBoardPanel.Left := 0;
  FBoardPanel.Width := 200;
  FBoardPanel.Height := 200;
  FBoardPanel.BorderStyle := bsSingle;
  FBoardPanel.DrawBlocks;

  Render;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Board.Restart;
  Render;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Board.Undo;
  Render;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FBoard.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case key of
    37 : FBoard.Move(dLeft);
    38 : FBoard.Move(dUp);
    39 : FBoard.Move(dRight);
    40 : FBoard.Move(dDown);
  end;
  Render;
end;

procedure TForm1.SetBoard(AValue: T2048Board);
begin
  FBoard := AValue;
end;

procedure TForm1.Render;
var
  I, J: Integer;
  Linha, Value: String;
begin
  for I:=0 to FBoard.Size-1 do
    for J:=0 to FBoard.Size-1 do
      FBoardPanel.FBlocks[I][J].Value := FBoard.Blocks[I][J].Value;

  Memo.Lines.Clear;

  for I:=0 to FBoard.Size-1 do
  begin
    Linha := '';
    for J:=0 to FBoard.Size-1 do
    begin
      Value := IntToStr(FBoard.Blocks[I][J].Value);

      if FBoard.Blocks[I][J].Value < 10 then
        Value := ' ' + Value;

      if Value = ' 0' then
        Value := '  ';
      Linha := Linha + Value + '|';
    end;
    Memo.Lines.Add(Linha);
  end;

  LScore.Caption := FBoard.Score.ToString;

  if Board.GameOver then
    Showmessage('Game Over!');
end;

end.

