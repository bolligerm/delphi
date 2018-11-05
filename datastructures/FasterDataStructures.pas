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
  //
  // It is most useful for stringlists with many items (at least 100 items
  // or more, but most notably useful with, say, tens of thousands of items).
  // This class does its special magic only when Sorted = False.
  // When Sorted = True, it handles everything using TStringList's original methods.
  //
  // This class will be less efficient if the individual strings are very long
  // (say, hundreds of characters each) - then the dictionary's slow hash
  // computation may outweigh the speed gained from using the dictionary
  // Insights from:
  // https://www.delphitools.info/2015/03/17/long-strings-hash-vs-sorted-vs-unsorted/
  //
  // TODO: Known issues:
  // - CaseSensitive = False should be supported (currently IndexOf disregards it)
  // - Changing/Changed correct support (using UpdateCount internally)
  //
  TFastLookupStringList = class(TStringList)
  private
    // Whether this list had Sorted = True last time we looked at it
    FWasSorted: Boolean;
    // Dictionary of all unique strings in this list, giving each string's index
    // (or the index of the first occurrence of it, if there are duplicates).
    // Used only when Sorted = False
    FLookupDict: TDictionary<string, Integer>;

    procedure CheckWasSorted; inline;
    procedure RebuildLookupDict;
    procedure ReflectOverwrittenItemInDict(const OldString: string);
    procedure ReflectInsertedItemInDict(Index: Integer; const S: string;
      AlreadyExisted: Boolean);
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

procedure TFastLookupStringList.CheckWasSorted;
begin
  // If the list was Sorted last time we looked at it,
  // but now isn't Sorted, then we must (re)build the whole LookupDict
  if FWasSorted and not Sorted then
    RebuildLookupDict;
  FWasSorted := Sorted;
end;

procedure TFastLookupStringList.Assign(Source: TPersistent);
begin
  if (Source is TStringList) and TStringList(Source).Sorted then
    FLookupDict.Clear;  // Just to save memory, not really necessary functionally
  inherited;
  if not Sorted then
    RebuildLookupDict;
  FWasSorted := Sorted;
end;

procedure TFastLookupStringList.Clear;
begin
  inherited;
  FLookupDict.Clear;
end;

procedure TFastLookupStringList.Delete(Index: Integer);
var
  DictItem: TPair<string, Integer>;
  OldString: string;
begin
  OldString := Strings[Index];  // Remember the old string (the one at the index that will now be overwritten)
  inherited;
  if Sorted or FWasSorted then
  begin
    // If FWasSorted, then the dictionary isn't in useful shape, anyway.
    // Since this Delete procedure itself doesn't need the dictionary,
    // we can skip rebuilding it here, and let the next operation
    // that really needs it (such as IndexOf) rebuild it
    FWasSorted := True;
    Exit;
  end;

  // Shift items down
  for DictItem in FLookupDict do
    if DictItem.Value > Index then  // If this item was "to the right" of the deleted one,
      FLookupDict[DictItem.Key] := DictItem.Value - 1;  // then shift its index (the value) one step down.

  // Remove or re-point OldString in the dictionary
  ReflectOverwrittenItemInDict(OldString);
end;

procedure TFastLookupStringList.Exchange(Index1, Index2: Integer);
var
  s1, s2: string;

  function Min(A, B: Integer): Integer;
  begin
    if A < B then
      Result := A
    else
      Result := B;
  end;

begin
  if Sorted or FWasSorted then
  begin
    inherited;
    // If FWasSorted, then the dictionary isn't in useful shape, anyway.
    // Since this Exchange procedure itself doesn't need the dictionary,
    // we can skip rebuilding it here, and let the next operation
    // that really needs it (such as IndexOf) rebuild it
    FWasSorted := True;
    Exit;
  end;

  s1 := Strings[Index1];
  s2 := Strings[Index2];

  inherited;

  // The string that has moved "up" (i.e. is now at the larger index)
  // may have jumped past another occurence of the same string,
  // and that one is now the first occurrence. Must check for this
  // using the inherited (slow) IndexOf, and updated the dictionary accordingly
  if Index2 > Index1 then
  begin
    FLookupDict[s1] := Min(Index2, inherited IndexOf(s1));
    FLookupDict[s2] := Index1;
  end
  else
  begin
    FLookupDict[s1] := Index2;
    FLookupDict[s2] := Min(Index1, inherited IndexOf(s2));
  end;
end;

function TFastLookupStringList.IndexOf(const S: string): Integer;
begin
  // If the list was Sorted last time we looked at it,
  // but now isn't Sorted, then we must (re)build the whole LookupDict
  CheckWasSorted;

  if Sorted then
    Result := inherited
  else if not FLookupDict.TryGetValue(S, Result) then
    Result := -1;
end;

procedure TFastLookupStringList.InsertItem(Index: Integer; const S: string;
  AObject: TObject);
var
  DictItem: TPair<string, Integer>;
  AlreadyExisted: Boolean;
begin
  // If the list was Sorted last time we looked at it,
  // but now isn't Sorted, then we must (re)build the whole LookupDict
  CheckWasSorted;

  if Sorted then
  begin
    inherited;
    Exit;
  end;

  AlreadyExisted := FLookupDict.ContainsKey(S);

  inherited;

  // Check if S got added last in the list, or somewhere inside the list
  // (NB! Count has already been increased by the inherited InsertItem, therefore Count - 1)
  if Index < Count - 1 then
  begin
    // S was added somewhere inside the list (not at the end)
    // - in this case, we need to update all shifted indexes in the dictionary
    for DictItem in FLookupDict do
      if DictItem.Value >= Index then  // If this item was at or "to the right" of the newly inserted one,
        FLookupDict[DictItem.Key] := DictItem.Value + 1;  // then shift its index (the value) one step up.
  end;

  // Add the new item to the dictionary.
  // However, if S existed in it already before the insert (that can happen if duplicates are allowed),
  // then we need to check which one of the strings is the first, the existing one or the new one,
  // and make sure that the dictionary points to the first one of these (i.e. the one with the smallest index)
  ReflectInsertedItemInDict(Index, S, AlreadyExisted);
end;

procedure TFastLookupStringList.Put(Index: Integer; const S: string);
var
  OldString: string;
  AlreadyExisted: Boolean;
begin
  // If the list was Sorted last time we looked at it,
  // but now isn't Sorted, then we must (re)build the whole LookupDict
  CheckWasSorted;

  if Sorted then
  begin
    inherited;
    Exit;
  end;

  OldString := Strings[Index];  // Remember the old string (the one at the index that will now be overwritten)

  AlreadyExisted := FLookupDict.ContainsKey(S);

  inherited;

  // Remove or re-point OldString in the dictionary
  ReflectOverwrittenItemInDict(OldString);

  // Add the new item to the dictionary.
  // However, if S existed in it already before the insert (that can happen if duplicates are allowed),
  // then we need to check which one of the strings is the first, the existing one or the new one,
  // and make sure that the dictionary points to the first one of these (i.e. the one with the smallest index)
  ReflectInsertedItemInDict(Index, S, AlreadyExisted);
end;

procedure TFastLookupStringList.RebuildLookupDict;
var
  i: Integer;
begin
  FLookupDict.Clear;
  for i := 0 to Count - 1 do
    if not FLookupDict.ContainsKey(Strings[i]) then
      FLookupDict.Add(Strings[i], i);
end;

procedure TFastLookupStringList.ReflectInsertedItemInDict(
  Index: Integer; const S: string;
  AlreadyExisted: Boolean);
var
  IndexOfExisting: Integer;
begin
  // This procedure is called from InsertItem and Put.
  // It updates the dictionary to reflect the fact
  // that a new item (S) was inserted (or put) at Index.

  // Add the new item S to the dictionary.
  // However, if S existed in it already before (that can happen if duplicates are allowed),
  // then we need to check which one of the strings is the first, the existing one or the new one,
  // and make sure that the dictionary points to the first one of these (i.e. the one with the smallest index)
  if not AlreadyExisted then
    FLookupDict.Add(S, Index)
  else
  begin
    IndexOfExisting := FLookupDict[S];
    if Index < IndexOfExisting  then
      FLookupDict[S] := Index;
  end;
end;

procedure TFastLookupStringList.ReflectOverwrittenItemInDict(const OldString: string);
var
  IndexOfDuplicateOldString: Integer;
begin
  // This procedure is called from Delete and Put.
  // It updates the dictionary to reflect the fact
  // that an item (OldString) was overwritten.

  // Remove OldString from FLookupDict, but only if it's the last occurrence of this string in the list.
  // Since duplicates are allowed (they're always allowed in unsorted TStringLists),
  // there might still exist another item with the same old string
  IndexOfDuplicateOldString := inherited IndexOf(OldString);  // Must call inherited here, even if it's slow
  if IndexOfDuplicateOldString = -1 then
    // The old string happened to be unique in the list. Remove it from the dictionary
    FLookupDict.Remove(OldString)
  else
    // The old string exists in at least one other location in the list.
    // Re-point the old key to there
    FLookupDict[OldString] := IndexOfDuplicateOldString;
end;

end.
