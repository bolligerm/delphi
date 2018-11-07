unit LocaleAwareStringComparers;

interface

uses
  System.Generics.Defaults;

function GetStringComparer(UseLocale, CaseSensitive: Boolean): TStringComparer;


implementation

uses
  System.SysUtils, System.Hash;

type
  // General base class
  TStringComparerBase = class(TStringComparer)
  protected
    function GetComparableString(const Value: string): string; virtual; abstract;
  public
    function Compare(const Left, Right: string): Integer; override;
    function Equals(const Left, Right: string): Boolean;
      reintroduce; overload; override;
    function GetHashCode(const Value: string): Integer;
      reintroduce; overload; override;
  end;

  // Specific child classes
  TCaseSensitiveUseLocaleStringComparer = class(TStringComparerBase)
  private
    class var
      FComparer: TCustomComparer<string>;
  protected
    function GetComparableString(const Value: string): string; override;
    class destructor Destroy;
    class function GetComparer: TStringComparer;
  end;

  TCaseInsensitiveUseLocaleStringComparer = class(TStringComparerBase)
  private
    class var
      FComparer: TCustomComparer<string>;
  protected
    function GetComparableString(const Value: string): string; override;
    class destructor Destroy;
    class function GetComparer: TStringComparer;
  end;

  TCaseSensitiveNoLocaleStringComparer = class(TStringComparerBase)
  private
    class var
      FComparer: TCustomComparer<string>;
  protected
    function GetComparableString(const Value: string): string; override;
    class destructor Destroy;
    class function GetComparer: TStringComparer;
  end;

  TCaseInsensitiveNoLocaleStringComparer = class(TStringComparerBase)
  private
    class var
      FComparer: TCustomComparer<string>;
  protected
    function GetComparableString(const Value: string): string; override;
    class destructor Destroy;
    class function GetComparer: TStringComparer;
  end;


{ Utility function to get the suitable comparer }

function GetStringComparer(UseLocale, CaseSensitive: Boolean): TStringComparer;
begin
  if UseLocale then
    if CaseSensitive then
      Result := TCaseSensitiveUseLocaleStringComparer.GetComparer
    else
      Result := TCaseInsensitiveUseLocaleStringComparer.GetComparer
  else
    if CaseSensitive then
      Result := TCaseSensitiveNoLocaleStringComparer.GetComparer
    else
      Result := TCaseInsensitiveNoLocaleStringComparer.GetComparer;
end;

{ TStringComparerBase }

// The bulk of the code in these Compare, Equals and GetHashCode functions
// is taken from (i.e. duplicates what is in ) TOrdinalStringComparer in System.Generics.Defaults.
// I would have preferred to not copy the code here,
// but to simply make my TStringComparerBase a subclass of TOrdinalStringComparer.
// Unfortunately, TOrdinalStringComparer is declared only in the
// implementation section of System.Generics.Defaults,
// not in the interface section, thus making this approach impossible.
//
// (It is actually a strange thing that TOrdinalIStringComparer
// *is* in the interface section, but TOrdinalStringComparer is not.)

function TStringComparerBase.Compare(const Left, Right: string): Integer;
var
  L, R: string;
  len, lenDiff: Integer;
begin
  L := GetComparableString(Left);
  R := GetComparableString(Right);
  len := Length(L);
  lenDiff := len - Length(R);
  if Length(R) < len then
    len := Length(R);
  Result := BinaryCompare(PChar(L), PChar(R), len * SizeOf(Char));
  if Result = 0 then
    Exit(lenDiff);
end;

function TStringComparerBase.Equals(const Left, Right: string): Boolean;
var
  len: Integer;
  L, R: string;
begin
  L := GetComparableString(Left);
  R := GetComparableString(Right);
  len := Length(L);
  Result := (len - Length(R) = 0) and CompareMem(PChar(L), PChar(R), len * SizeOf(Char));
end;

function TStringComparerBase.GetHashCode(const Value: string): Integer;
var
  S: string;
begin
  S := GetComparableString(Value);
  Result := THashBobJenkins.GetHashValue(PChar(S)^, SizeOf(Char) * Length(S), 0);
end;

{ TCaseSensitiveUseLocaleStringComparer }

function TCaseSensitiveUseLocaleStringComparer.GetComparableString(
  const Value: string): string;
begin
  Result := Value;
end;

class destructor TCaseSensitiveUseLocaleStringComparer.Destroy;
begin
  FreeAndNil(FComparer);
end;

class function TCaseSensitiveUseLocaleStringComparer.GetComparer: TStringComparer;
begin
  if FComparer = nil then
    FComparer := Self.Create;
  Result := TStringComparer(FComparer);
end;

{ TCaseInsensitiveUseLocaleStringComparer }

function TCaseInsensitiveUseLocaleStringComparer.GetComparableString(
  const Value: string): string;
begin
  Result := AnsiLowerCase(Value);
end;

class destructor TCaseInsensitiveUseLocaleStringComparer.Destroy;
begin
  FreeAndNil(FComparer);
end;

class function TCaseInsensitiveUseLocaleStringComparer.GetComparer: TStringComparer;
begin
  if FComparer = nil then
    FComparer := Self.Create;
  Result := TStringComparer(FComparer);
end;

{ TCaseSensitiveNoLocaleStringComparer }

function TCaseSensitiveNoLocaleStringComparer.GetComparableString(
  const Value: string): string;
begin
  Result := Value;
end;

class destructor TCaseSensitiveNoLocaleStringComparer.Destroy;
begin
  FreeAndNil(FComparer);
end;

class function TCaseSensitiveNoLocaleStringComparer.GetComparer: TStringComparer;
begin
  if FComparer = nil then
    FComparer := Self.Create;
  Result := TStringComparer(FComparer);
end;

{ TCaseInsensitiveNoLocaleStringComparer }

function TCaseInsensitiveNoLocaleStringComparer.GetComparableString(
  const Value: string): string;
begin
  Result := LowerCase(Value);
end;

class destructor TCaseInsensitiveNoLocaleStringComparer.Destroy;
begin
  FreeAndNil(FComparer);
end;

class function TCaseInsensitiveNoLocaleStringComparer.GetComparer: TStringComparer;
begin
  if FComparer = nil then
    FComparer := Self.Create;
  Result := TStringComparer(FComparer);
end;

end.
