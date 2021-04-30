unit UnitUser2;

interface

uses
  UnitA2;

function DoubleUp(AValue: TAlpha): TAlpha;


implementation

function DoubleUp(AValue: TAlpha): TAlpha;
begin
  Result := AValue + AValue;
end;

end.

