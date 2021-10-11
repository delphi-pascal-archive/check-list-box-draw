unit F_SysUtils;

interface

uses
  Windows;

function LoadStringW_GetResource(I : Integer) : WideString;
function IntToStr(I : Integer) : String;
function Format(FmtStr : String; Params : Array of const) : WideString;

implementation

function LoadStringW_GetResource(I : Integer) : WideString;
var
  Buffer : Array [0..255] of WideChar;
begin
  LoadStringW(hInstance, I, Buffer, SizeOf(Buffer));
  Result := Buffer;
end;

function IntToStr(I : Integer) : String;
begin
  Str(I, Result);
end;

function Format(FmtStr : String; Params : Array of const) : WideString;
var
  PDW1 : PDWORD;
  PDW2 : PDWORD;
  I    : Integer;
  PC   : PChar;
begin
  PDW1 := nil;
  if Length(Params) > 0 then
    GetMem(PDW1, Length(Params) * SizeOf(Pointer));
  PDW2 := PDW1;
  for I := 0 to High(Params) do
    begin
      PDW2^ := DWORD(PDWORD(@Params[I])^);
      Inc(PDW2);
    end;
  GetMem(PC, 1024 - 1);
  try
    SetString(Result, PC, wvsprintf(PC, PChar(FmtStr), PChar(PDW1)));
  except
    Result := '';
  end;
  if (PDW1 <> nil) then
    FreeMem(PDW1);
  if (PC <> nil) then
    FreeMem(PC);
end;

end.