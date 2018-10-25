unit FasterDataStructures;

{
MIT License

Copyright (c) 2018 Matthias Bolliger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

interface

uses
  System.Generics.Collections, System.Classes;

type
  //
  // TFastLookupStringList - has the exact same functionality as a TStringList
  // but does fast lookups (IndexOf) even if it is not sorted.
  // It accomplishes this by using an internal dictionary.
  // It is mostly useful for large stringlists (say, 100 items or more).
  // This class does its special magic only when Sorted = False.
  // When Sorted = True, it handles everything using TStringList's original methods.
  //
  TFastLookupStringList = class(TStringList)
  private
    FLookupDict: TDictionary<string, Integer>;
    procedure RebuildLookupDict;
  protected
    procedure Put(Index: Integer; const S: string); override;
    procedure InsertItem(Index: Integer; const S: string; AObject: TObject); override;
  public
    constructor Create; overload;
    constructor Create(OwnsObjects: Boolean); overload;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1, Index2: Integer); override;
    function IndexOf(const S: string): Integer; override;
  end;

implementation

{ TFastLookupStringList }

constructor TFastLookupStringList.Create;
begin
  inherited Create;
  FLookupDict := TDictionary<string, Integer>.Create;
end;

constructor TFastLookupStringList.Create(OwnsObjects: Boolean);
begin
  inherited Create(OwnsObjects);
  FLookupDict := TDictionary<string, Integer>.Create;
end;

destructor TFastLookupStringList.Destroy;
begin
  FLookupDict.Free;
  inherited;
end;

procedure TFastLookupStringList.Assign(Source: TPersistent);
begin
  inherited;
  RebuildLookupDict;
end;

procedure TFastLookupStringList.Clear;
begin
  inherited;
  FLookupDict.Clear;
end;

procedure TFastLookupStringList.Delete(Index: Integer);
var
  DictItem: TPair<string, Integer>;
begin
  inherited;
  for DictItem in FLookupDict do
    if DictItem.Value > Index then  // If this item was "to the right" of the newly inserted one,
      FLookupDict[DictItem.Key] := DictItem.Value - 1;  // then shift its index (the value) one step down.
end;

procedure TFastLookupStringList.Exchange(Index1, Index2: Integer);
var
  s1, s2: string;
begin
  s1 := Strings[Index1];
  s2 := Strings[Index2];
  inherited;
  FLookupDict[s1] := Index2;
  FLookupDict[s2] := Index1;
end;

function TFastLookupStringList.IndexOf(const S: string): Integer;
begin
  if Sorted then
    Result := inherited
  else if not FLookupDict.TryGetValue(S, Result) then
    Result := -1;
end;

procedure TFastLookupStringList.InsertItem(Index: Integer; const S: string;
  AObject: TObject);
var
  DictItem: TPair<string, Integer>;
begin
  inherited;
  if Index = Count - 1 then  // (FCount has already been increased by the inherited InsertItem)
  begin
    // S was added at end of list
    // - simple case: we just add the new item to the dictionary
    FLookupDict.Add(S, Index);
  end
  else
  begin
    // S was added somewhere inside the list (not at the end)
    // - trickier case: we need to update all shifted indexes in the dictionary
    for DictItem in FLookupDict do
      if DictItem.Value >= Index then  // If this item was at or "to the right" of the newly inserted one,
        FLookupDict[DictItem.Key] := DictItem.Value + 1;  // then shift its index (the value) one step up.
  end;
end;

procedure TFastLookupStringList.Put(Index: Integer; const S: string);
var
  OldString: string;
  IndexOfDuplicateOldString: Integer;
begin
  OldString := Strings[Index];  // Remember the old string (the one at the index that will now be overwritten)

  inherited;

  if Duplicates = dupAccept then
  begin
    // With duplicates allowed, there might still exist another item with the same old string
    IndexOfDuplicateOldString := inherited IndexOf(OldString);  // Must call inherited here, even if it's slow
    if IndexOfDuplicateOldString = -1 then
      // The old string happened to be unique in the list. Remove it from the dictionary
      FLookupDict.Remove(OldString)
    else
      // The old string exists in at least one other location in the list.
      // Re-point the old key to there
      FLookupDict[OldString] := IndexOfDuplicateOldString;
  end
  else
    // No duplicates allowed. We can simply remove the old key
    FLookupDict.Remove(OldString);

  // In all cases, add the new one
  FLookupDict.Add(S, Index);
end;

procedure TFastLookupStringList.RebuildLookupDict;
var
  i: Integer;
begin
  FLookupDict.Clear;
  for i := 0 to Count - 1 do
    FLookupDict.Add(Strings[i], i);
end;

end.
