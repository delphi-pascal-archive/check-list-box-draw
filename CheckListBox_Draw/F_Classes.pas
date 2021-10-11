unit F_Classes;

interface

uses
  Windows;

function Rect(Left, Top, Right, Bottom : Integer) : TRect;

implementation

function Rect(Left, Top, Right, Bottom : Integer) : TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Bottom := Bottom;
  Result.Right := Right;
end;

end.