unit FasterDataStructures;

{
MIT License

Copyright (c) 2018-2025 Matthias Bolliger

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
  TFastLookupStringList = class(TStringList)
  {$IF RTLVersion < 32.0}
  private
  // In versions before Delphi Tokyo, TStrings did not have a UseLocale property,
  // and TStringList handled all strings according to the locale,
  // i.e. in the way Delphi Tokyo and up handle them when UseLocale = True
  const
    UseLocale = True;
  {$IFEND}
  private
    // Whether this list had CaseSensitive = True last time we looked at it
    FWasCaseSensitive: Boolean;
    // Whether this list had UseLocale = True last time we looked at it
    FWasUseLocale: Boolean;
    // Whether this list had Sorted = True last time we looked at it
    FWasSorted: Boolean;
    // Dictionary of all unique strings in this list, giving each string's index
    // (or the index of the first occurrence of it, if there are duplicates).
    // Used only when Sorted = False
    FLookupDict: TDictionary<string, Integer>;

    procedure CheckForChangedCaseSensitiveOrSorted; inline;
    function Dictify(const s: string): string; inline;
    procedure CreateLookupDict;
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
{$IF RTLVersion >= 32.0}
    // Additional constructors, available only in Delphi Tokyo and up
    constructor Create(QuoteChar, Delimiter: Char); overload;
    constructor Create(QuoteChar, Delimiter: Char; Options: TStringsOptions); overload;
    constructor Create(Duplicates: TDuplicates; Sorted: Boolean; CaseSensitive: Boolean); overload;
{$IFEND}
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1, Index2: Integer); override;
    function IndexOf(const S: string): Integer; override;
  end;

implementation

uses
  System.SysUtils, System.Generics.Defaults;  // Not used now: LocaleAwareStringComparers;

{ TFastLookupStringList }

constructor TFastLookupStringList.Create;
begin
  inherited;
  CreateLookupDict;
end;

constructor TFastLookupStringList.Create(OwnsObjects: Boolean);
begin
  inherited;
  CreateLookupDict;
end;

{$IF RTLVersion >= 32.0}
constructor TFastLookupStringList.Create(QuoteChar, Delimiter: Char);
begin
  inherited;
  CreateLookupDict;
end;

constructor TFastLookupStringList.Create(QuoteChar, Delimiter: Char;
  Options: TStringsOptions);
begin
  inherited;
  CreateLookupDict;
end;

constructor TFastLookupStringList.Create(Duplicates: TDuplicates; Sorted,
  CaseSensitive: Boolean);
begin
  inherited;
  CreateLookupDict;
end;
{$IFEND}

destructor TFastLookupStringList.Destroy;
begin
  FLookupDict.Free;
  inherited;
end;

function TFastLookupStringList.Dictify(const s: string): string;
begin
  // It may seem like it could be bad for performance
  // to call AnsiLowerCase (via Dictify here) every time the dictionary is accessed.
  // However, the alternative would be to let the dictionary be created with
  // TDictionary<string, Integer>.Create(TIStringComparer.Ordinal),
  // and that comparer would call AnsiLowerCase even more times:
  // twice in its Compare and Equals methods and once in its GetHashCode method
  // (see System.Generics.Defaults).
  // TDictionary.GetItem calls GetHashCode once and Equals at least once (sometimes multiple times),
  // so in total, we would end up calling AnsiLowerCase more times (possibly many more).
  //
  // Plus, by using our own Dictify, we can properly support the non-UseLocale case, too.

  if CaseSensitive then
    Result := s
  else if UseLocale then
    Result := AnsiLowerCase(s)
  else
    Result := LowerCase(s);
end;

procedure TFastLookupStringList.CheckForChangedCaseSensitiveOrSorted;
begin
  // If we are non-Sorted, then we need the dictionary.
  // The dictionary needs a full rebuild if
  // the list was Sorted last time we looked at it (but now isn't),
  // or CaseSensitive or UseLocale has changed.
  if (not Sorted) and
     (FWasSorted or (FWasCaseSensitive <> CaseSensitive) or (FWasUseLocale <> UseLocale)) then
    RebuildLookupDict;

  FWasCaseSensitive := CaseSensitive;
  FWasUseLocale := UseLocale;
  FWasSorted := Sorted;
end;

procedure TFastLookupStringList.Assign(Source: TPersistent);
begin
  BeginUpdate;
  if (Source is TStringList) and TStringList(Source).Sorted then
    FLookupDict.Clear;  // Just to save memory, not really necessary functionally
  inherited;
  if not Sorted then
    RebuildLookupDict;
  FWasSorted := Sorted;
  FWasCaseSensitive := CaseSensitive;
  FWasUseLocale := UseLocale;
  EndUpdate;
end;

procedure TFastLookupStringList.Clear;
begin
  BeginUpdate;
  inherited;
  FLookupDict.Clear;
  EndUpdate;
end;

procedure TFastLookupStringList.Delete(Index: Integer);
var
  DictItem: TPair<string, Integer>;
  OldString: string;
begin
  BeginUpdate;
  OldString := Strings[Index];  // Remember the old string (the one at the index that will now be overwritten)
  inherited;
  if Sorted or FWasSorted then
  begin
    // If FWasSorted, then the dictionary isn't in useful shape, anyway.
    // Since this Delete procedure itself doesn't need the dictionary,
    // we can skip rebuilding it here, and let the next operation
    // that really needs it (such as IndexOf) rebuild it
    FWasSorted := True;
  end
  else
  begin
    // Shift items after the deleted one "to the left"
    for DictItem in FLookupDict do
      if DictItem.Value > Index then  // If this item was "to the right" of the deleted one,
        FLookupDict[DictItem.Key] := DictItem.Value - 1;  // then shift its index (the value) one step "to the left".

    // Remove or re-point OldString in the dictionary
    ReflectOverwrittenItemInDict(OldString);
  end;
  EndUpdate;
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
  BeginUpdate;
  if Sorted or FWasSorted then
  begin
    inherited;
    // If FWasSorted, then the dictionary isn't in useful shape, anyway.
    // Since this Exchange procedure itself doesn't need the dictionary,
    // we can skip rebuilding it here, and let the next operation
    // that really needs it (such as IndexOf) rebuild it
    FWasSorted := True;
  end
  else
  begin
    s1 := Strings[Index1];
    s2 := Strings[Index2];

    inherited;

    // The string that has moved "up" (i.e. is now at the larger index)
    // may have jumped past another occurence of the same string,
    // and that one is now the first occurrence. Must check for this
    // using the inherited (slow) IndexOf, and update the dictionary accordingly
    if Index2 > Index1 then
    begin
      FLookupDict[Dictify(s1)] := Min(Index2, inherited IndexOf(s1));
      FLookupDict[Dictify(s2)] := Index1;
    end
    else
    begin
      FLookupDict[Dictify(s1)] := Index2;
      FLookupDict[Dictify(s2)] := Min(Index1, inherited IndexOf(s2));
    end;
  end;
  EndUpdate;
end;

function TFastLookupStringList.IndexOf(const S: string): Integer;
begin
  // If the list's CaseSensitive or Sorted properties have changed since last time we looked at it,
  // then we must recreate and/or (re)build the whole LookupDict
  CheckForChangedCaseSensitiveOrSorted;

  if Sorted then
    Result := inherited
  else if not FLookupDict.TryGetValue(Dictify(S), Result) then
    Result := -1;
end;

procedure TFastLookupStringList.InsertItem(Index: Integer; const S: string;
  AObject: TObject);
var
  DictItem: TPair<string, Integer>;
  AlreadyExisted: Boolean;
begin
  BeginUpdate;

  // If the list's CaseSensitive or Sorted properties have changed since last time we looked at it,
  // then we must recreate and/or (re)build the whole LookupDict
  CheckForChangedCaseSensitiveOrSorted;

  if Sorted then
  begin
    inherited;
  end
  else
  begin
    AlreadyExisted := FLookupDict.ContainsKey(Dictify(S));
    inherited;

    // Check if S got added last in the list, or somewhere inside the list
    // (NB! Count has already been increased by the inherited InsertItem, therefore Count - 1)
    if Index < Count - 1 then
    begin
      // S was added somewhere inside the list (not at the end)
      // - in this case, we need to update all shifted indexes in the dictionary:
      // Shift items at or after the inserted one "to the right"
      for DictItem in FLookupDict do
        if DictItem.Value >= Index then  // If this item was at or "to the right" of the newly inserted one,
          FLookupDict[DictItem.Key] := DictItem.Value + 1;  // then shift its index (the value) one step "to the right".
    end;

    // Add the new item to the dictionary.
    // However, if S existed in it already before the insert (that can happen if duplicates are allowed),
    // then we need to check which one of the strings is the first, the existing one or the new one,
    // and make sure that the dictionary points to the first one of these (i.e. the one with the smallest index)
    ReflectInsertedItemInDict(Index, S, AlreadyExisted);
  end;

  EndUpdate;
end;

procedure TFastLookupStringList.Put(Index: Integer; const S: string);
var
  OldString: string;
  AlreadyExisted: Boolean;
begin
  BeginUpdate;

  // If the list's CaseSensitive or Sorted properties have changed since last time we looked at it,
  // then we must recreate and/or (re)build the whole LookupDict
  CheckForChangedCaseSensitiveOrSorted;

  if Sorted then
  begin
    inherited;
  end
  else
  begin
    OldString := Strings[Index];  // Remember the old string (the one at the index that will now be overwritten)

    AlreadyExisted := FLookupDict.ContainsKey(Dictify(S));

    inherited;

    // Remove or re-point OldString in the dictionary
    ReflectOverwrittenItemInDict(OldString);

    // Add the new item to the dictionary.
    // However, if S existed in it already before the insert (that can happen if duplicates are allowed),
    // then we need to check which one of the strings is the first, the existing one or the new one,
    // and make sure that the dictionary points to the first one of these (i.e. the one with the smallest index)
    ReflectInsertedItemInDict(Index, S, AlreadyExisted);
  end;

  EndUpdate;
end;

procedure TFastLookupStringList.CreateLookupDict;
begin
  FLookupDict := TDictionary<string, Integer>.Create;
end;

procedure TFastLookupStringList.RebuildLookupDict;
var
  i: Integer;
begin
  FLookupDict.Clear;
  for i := 0 to Count - 1 do
    if not FLookupDict.ContainsKey(Dictify(Strings[i])) then
      FLookupDict.Add(Dictify(Strings[i]), i);
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
    FLookupDict.Add(Dictify(S), Index)
  else
  begin
    IndexOfExisting := FLookupDict[Dictify(S)];
    if Index < IndexOfExisting  then
      FLookupDict[Dictify(S)] := Index;
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
    FLookupDict.Remove(Dictify(OldString))
  else
    // The old string exists in at least one other location in the list.
    // Re-point the old key to there
    FLookupDict[Dictify(OldString)] := IndexOfDuplicateOldString;
end;

end.
