unit u2048;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TDirection = (dLeft, dRight, dUp, dDown);
  TNewBlockEvent = procedure(Row, Col: Integer; Value: Integer) of Object;
  TMoveEvent = procedure(Direction: TDirection; ValidMove: Boolean) of Object;
  TGameOverEvent = procedure() of Object;

  { T2048Block }

  T2048Block = class
  private
    FUndoValue: Integer;
    FValue: Integer;
    procedure SetValue(AValue: Integer);
  public
    constructor Create(Value: Integer=0);
    procedure Undo;
    property Value: Integer read FValue write SetValue;
  end;

  { T2048Board }

  T2048Blocks = array of array of T2048Block;

  T2048Board = class
  private
    FGameOver: Boolean;
    FOnGameOver: TGameOverEvent;
    FSize: Integer;
    FBlocks: T2048Blocks;
    FOnMove: TMoveEvent;
    FOnNewBlock: TNewBlockEvent;
    FUndoScore: Integer;
    FScore: Integer;
    procedure SetOnGameOver(AValue: TGameOverEvent);
    function TryMoveAndMergeCells(var Cells: array of Integer; var Score: Integer): Boolean;
    function CountFreeBlocks: Integer;
    procedure NewBlock;
    procedure CheckGameOver;
    procedure SetOnMove(AValue: TMoveEvent);
    procedure SetOnNewBlock(AValue: TNewBlockEvent);
  public
    constructor Create(Size: Integer=4);
    destructor Destroy; override;
    procedure Restart;
    procedure Move(Direction: TDirection);
    procedure Undo;
    property Size: Integer read FSize;
    property Score: Integer read FScore;
    property GameOver: Boolean read FGameOver;
    property Blocks: T2048Blocks read FBlocks;
    property OnNewBlock: TNewBlockEvent read FOnNewBlock write SetOnNewBlock;
    property OnMove: TMoveEvent read FOnMove write SetOnMove;
    property OnGameOver: TGameOverEvent read FOnGameOver write SetOnGameOver;
  end;

implementation

uses
  Math;

function T2048Board.TryMoveAndMergeCells(var Cells: array of Integer;
  var Score: Integer): Boolean;
  function MoveValues: Boolean;
  var
    I, J: Integer;
  begin
    J := 0;
    Result := False;
    for I:=0 to Length(Cells)-1 do
    begin
      if Cells[I] = 0 then
        Continue;

      if I = J then
      begin
        Inc(J);
        Continue;
      end;

      Cells[J] := Cells[I];
      Cells[I] := 0;
      Inc(J);
      Result := True;
    end;
  end;
var
  K: Integer;
begin
  Result := False;
  for K:=0 to Length(Cells)-2 do
  begin
    Result := MoveValues or Result;

    if (Cells[K] > 0) and (Cells[K] = Cells[K+1]) then
    begin
      Inc(Cells[K]);
      Cells[K+1] := 0;

      Score := Score + Trunc(Power(2, Cells[K]));
      Result := True;
    end;
  end;
end;

procedure T2048Board.SetOnGameOver(AValue: TGameOverEvent);
begin
  FOnGameOver := AValue;
end;

function T2048Board.CountFreeBlocks: Integer;
var
  I, J: Integer;
begin
  Result := 0;
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      if FBlocks[I][J].Value = 0 then
        Inc(Result);
end;

procedure T2048Board.NewBlock;
  procedure NewBlockEvent(Row, Col, Value: Integer);
  begin
    try
      if Assigned(FOnNewBlock) then
        FOnNewBlock(Row, Col, Value);
    finally
    end;
  end;
var
  RandomLimit: Integer;
  Pos: Integer;
  I, J, K: Integer;
  NextValue: Integer;
begin
  RandomLimit := CountFreeBlocks;
  if RandomLimit = 0 then
    Exit;

  // sorteia a posição para do novo bloco
  Randomize;
  Pos := Random(RandomLimit);

  //sorteia o novo valor do bloco (2 ou 4). 90% para 1. 10% para 2.
  NextValue := Random(10);
  NextValue := IfThen(NextValue = 9, 2, 1); //2 --> 2^2=4  / 1 --> 2^1=2

  K := 0;
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      if FBlocks[I][J].Value = 0 then
      begin
        if K = Pos then
        begin
          FBlocks[I][J].FValue := NextValue; //tem que ser direto no FValue para o FUndoValue não ser alterado
          NewBlockEvent(I, J, NextValue);
          Exit;
        end;

        Inc(K);
      end;
end;

procedure T2048Board.CheckGameOver;
var
  I, J: Integer;
begin
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      if FBlocks[I][J].Value = 0 then
        Exit;

  for I:=0 to FSize-1 do
    for J:=0 to FSize-2 do
      if FBlocks[I][J].Value = FBlocks[I][J+1].Value then
        Exit;

  for I:=0 to FSize-2 do
    for J:=0 to FSize-1 do
      if FBlocks[I][J].Value = FBlocks[I+1][J].Value then
        Exit;

  FGameOver := True;
end;

procedure T2048Board.SetOnMove(AValue: TMoveEvent);
begin
  FOnMove := AValue;
end;

procedure T2048Board.SetOnNewBlock(AValue: TNewBlockEvent);
begin
  FOnNewBlock := AValue;
end;

{ T2048Block }

procedure T2048Block.SetValue(AValue: Integer);
begin
  FUndoValue := FValue;
  FValue := AValue;
end;

constructor T2048Block.Create(Value: Integer=0);
begin
  if Value < 0 then
    Value := 0;
  FValue := Value;
end;

procedure T2048Block.Undo;
begin
  FValue := FUndoValue;
end;

{ T2048Board }

constructor T2048Board.Create(Size: Integer=4);
var
  I, J: Integer;
begin
  if Size < 2 then
    Size := 2;
  FSize := Size;
  SetLength(FBlocks, Size, Size);
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      FBlocks[I][J] := T2048Block.Create;
end;

destructor T2048Board.Destroy;
var
  I, J: Integer;
begin
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      FBlocks[I][J].Free;
end;

procedure T2048Board.Restart;
var
  I, J: Integer;
begin
  FUndoScore := 0;
  FScore := 0;
  FGameOver := False;
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      FBlocks[I][J].Value := 0;
  NewBlock;
end;

procedure T2048Board.Move(Direction: TDirection);
var
  I, J: Integer;
  Cells: array of array of Integer;
  ValidMovement: Boolean;
  FUndoScoreTemp: Integer;

  function PosCells: Integer;
  begin
    if Direction in [dLeft, dUp] then
      Result := J;
    if Direction in [dRight, dDown] then
      Result := FSize-1-J;
  end;

  function Row: Integer;
  begin
    if Direction in [dLeft, dRight] then
      Result := I;
    if Direction in [dUp, dDown] then
      Result := J;
  end;

  function Col: Integer;
  begin
    if Direction in [dLeft, dRight] then
      Result := J;
    if Direction in [dUp, dDown] then
      Result := I;
  end;
begin
  try
    if GameOver then
      Exit;

    FUndoScoreTemp := FScore;
    ValidMovement := False;
    Cells := nil;
    SetLength(Cells, Size, Size);

    for I:=0 to FSize-1 do
    begin
      for J:=0 to FSize-1 do
        Cells[I][PosCells] := FBlocks[Row][Col].Value;

      ValidMovement := TryMoveAndMergeCells(Cells[I], FScore) or ValidMovement;
    end;

    if not ValidMovement then
      Exit;

    FUndoScore := FUndoScoreTemp;

    for I:=0 to FSize-1 do
      for J:=0 to FSize-1 do
        FBlocks[Row][Col].Value := Cells[I][PosCells];

    NewBlock;
    CheckGameOver;
  finally
    if Assigned(FOnMove) then
      FOnMove(Direction, ValidMovement);
  end;
end;

procedure T2048Board.Undo;
var
  I, J: Integer;
begin
  FGameOver := False;
  FScore := FUndoScore;
  for I:=0 to FSize-1 do
    for J:=0 to FSize-1 do
      FBlocks[I][J].Undo;
end;

end.

