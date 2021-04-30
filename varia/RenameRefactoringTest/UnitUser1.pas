unit UnitUser1;

interface

uses
  UnitA1;

function DoubleUp(AValue: TAlpha): TAlpha;


implementation

function DoubleUp(AValue: TAlpha): TAlpha;
begin
  Result := AValue + AValue;
end;

end.
