unit TestFasterDataStructures;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit
  being tested.

}

interface

uses
  TestFramework, System.Classes, FasterDataStructures, System.Generics.Collections;

type
  // Test methods for class TFastLookupStringList

  TestTFastLookupStringList = class(TTestCase)
  strict private
    FFastLookupStringList: TFastLookupStringList;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAssign;
    procedure TestAssignSorted;
    procedure TestClear;
    procedure TestDelete;
    procedure TestExchange;
    procedure TestIndexOf;
    procedure TestPut;
    procedure TestInsert;
    procedure TestCaseInsensitive;
  end;

implementation

procedure TestTFastLookupStringList.SetUp;
begin
  FFastLookupStringList := TFastLookupStringList.Create;
  FFastLookupStringList.Add('Original First');
  FFastLookupStringList.Add('Original Second');
  FFastLookupStringList.Add('Original Third');
  FFastLookupStringList.Add('Original Fourth');
  FFastLookupStringList.Add('Original Fifth');
end;

procedure TestTFastLookupStringList.TearDown;
begin
  FFastLookupStringList.Free;
  FFastLookupStringList := nil;
end;

procedure TestTFastLookupStringList.TestAssign;
var
  Source: TPersistent;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Add('One');
    SL.Add('Two');
    SL.Add('Three');
    SL.Add('One');  // Repeat One
    SL.Add('Five');
    SL.Add('Six');
    SL.Add('Seven');
    Source := SL;
    FFastLookupStringList.Assign(Source);
    CheckEquals(SL.Count, FFastLookupStringList.Count, 'Count differs after Assign');
    CheckEquals(SL[0], FFastLookupStringList[0], 'Item 0 differs after Assign');
    CheckEquals(SL[1], FFastLookupStringList[1], 'Item 1 differs after Assign');
    CheckEquals(0, FFastLookupStringList.IndexOf('One'), 'IndexOf One after Assign');  // Must be 0, not 3
    CheckEquals(1, FFastLookupStringList.IndexOf('Two'), 'IndexOf Two after Assign');
    CheckEquals(-1, FFastLookupStringList.IndexOf('Original First'), 'IndexOf Original First after Assign');
    CheckEquals(-1, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf Original Third after Assign');
  finally
    SL.Free;
  end;
end;

procedure TestTFastLookupStringList.TestAssignSorted;
var
  Source: TPersistent;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Sorted := True;
    SL.Add('One');
    SL.Add('Two');
    Source := SL;
    FFastLookupStringList.Assign(Source);
    CheckEquals(SL.Count, FFastLookupStringList.Count, 'Count differs after Assign Sorted');
    CheckEquals(SL[0], FFastLookupStringList[0], 'Item 0 differs after Assign Sorted');
    CheckEquals(SL[1], FFastLookupStringList[1], 'Item 1 differs after Assign Sorted');
    CheckEquals(0, FFastLookupStringList.IndexOf('One'), 'IndexOf One after Assign Sorted');
    CheckEquals(1, FFastLookupStringList.IndexOf('Two'), 'IndexOf Two after Assign Sorted');
    CheckEquals(-1, FFastLookupStringList.IndexOf('Original First'), 'IndexOf Original First after Assign Sorted');
    CheckEquals(-1, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf Original Third after Assign Sorted');
  finally
    SL.Free;
  end;
end;

procedure TestTFastLookupStringList.TestCaseInsensitive;
begin
  // Add a string with letters outside a-z (to make UseLocale matter)
  FFastLookupStringList.Add('�una s�da');

  // Here UseLocale = True (the default)
  FFastLookupStringList.CaseSensitive := False;
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf in case-insensitive list, a');
  CheckEquals(2, FFastLookupStringList.IndexOf('Original THIRD'), 'IndexOf in case-insensitive list, b');
  CheckEquals(5, FFastLookupStringList.IndexOf('�una s�da'), 'IndexOf in case-insensitive list, c');
  CheckEquals(5, FFastLookupStringList.IndexOf('�uNA S�da'), 'IndexOf in case-insensitive list, d');  // INTERESTING DIFFERENCE
  FFastLookupStringList.CaseSensitive := True;
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf in case-sensitive list, a');
  CheckEquals(-1, FFastLookupStringList.IndexOf('Original THIRD'), 'IndexOf in case-sensitive list, b');
  CheckEquals(5, FFastLookupStringList.IndexOf('�una s�da'), 'IndexOf in case-sensitive list, c');
  CheckEquals(-1, FFastLookupStringList.IndexOf('�uNA S�da'), 'IndexOf in case-sensitive list, d');

  // Now we set UseLocale = False
{$IF RTLVersion >= 32.0}
  FFastLookupStringList.UseLocale := False;
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf in non-locale case-sensitive list, a');
  CheckEquals(-1, FFastLookupStringList.IndexOf('Original THIRD'), 'IndexOf in non-locale case-sensitive list, b');
  CheckEquals(5, FFastLookupStringList.IndexOf('�una s�da'), 'IndexOf in non-locale case-sensitive list, c');
  CheckEquals(-1, FFastLookupStringList.IndexOf('�uNA S�da'), 'IndexOf in non-locale case-sensitive list, d');
  FFastLookupStringList.CaseSensitive := False;
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf in non-locale case-insensitive list, a');
  CheckEquals(2, FFastLookupStringList.IndexOf('Original THIRD'), 'IndexOf in non-locale case-insensitive list, b');
  CheckEquals(5, FFastLookupStringList.IndexOf('�una s�da'), 'IndexOf in non-locale case-insensitive list, c');
  CheckEquals(-1, FFastLookupStringList.IndexOf('�uNA S�da'), 'IndexOf in non-locale case-insensitive list, d');  // INTERESTING DIFFERENCE

  // Set UseLocale = True again
  FFastLookupStringList.UseLocale := True;
  CheckEquals(5, FFastLookupStringList.IndexOf('�uNA S�da'), 'IndexOf in again-locale case-insensitive list, d');  // INTERESTING DIFFERENCE
  // Set UseLocale = False again
  FFastLookupStringList.UseLocale := False;
  CheckEquals(-1, FFastLookupStringList.IndexOf('�uNA S�da'), 'IndexOf in again-non-locale case-insensitive list, d');  // INTERESTING DIFFERENCE
{$IFEND}
end;

procedure TestTFastLookupStringList.TestClear;
begin
  FFastLookupStringList.Clear;
  CheckEquals(0, FFastLookupStringList.Count, 'Count after Clear');
end;

procedure TestTFastLookupStringList.TestDelete;
var
  Index: Integer;
begin
  Index := 3;
  FFastLookupStringList.Delete(Index);
  CheckEquals(4, FFastLookupStringList.Count, 'Count after Delete');
  CheckEquals('Original Fifth', FFastLookupStringList[3], 'Contents after Delete');
  CheckEquals('Original Third', FFastLookupStringList[2], 'Contents after Delete');
  // IndexOf tests
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf after Delete');
  CheckEquals(3, FFastLookupStringList.IndexOf('Original Fifth'), 'IndexOf after Delete');
  CheckEquals(-1, FFastLookupStringList.IndexOf('Original Fourth'), 'IndexOf after Delete');
end;

procedure TestTFastLookupStringList.TestExchange;
begin
  FFastLookupStringList.Exchange(0, 2);
  CheckEquals('Original First', FFastLookupStringList[2], 'Contents after Exchange');
  CheckEquals('Original Third', FFastLookupStringList[0], 'Contents after Exchange');
  // IndexOf tests
  CheckEquals(0, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf after Exchange');
  CheckEquals(2, FFastLookupStringList.IndexOf('Original First'), 'IndexOf after Exchange');
  CheckEquals(3, FFastLookupStringList.IndexOf('Original Fourth'), 'IndexOf after Exchange');
  // Some more tests, with duplicates
  FFastLookupStringList.Add('Original Second');
  CheckEquals(1, FFastLookupStringList.IndexOf('Original Second'), 'IndexOf after Exchange with duplicates, a');
  FFastLookupStringList.Exchange(0, 5);
  CheckEquals(0, FFastLookupStringList.IndexOf('Original Second'), 'IndexOf after Exchange with duplicates, b');
  FFastLookupStringList.Exchange(0, 5);
  CheckEquals(1, FFastLookupStringList.IndexOf('Original Second'), 'IndexOf after Exchange with duplicates, c');  // Must be 1, not 5
end;

procedure TestTFastLookupStringList.TestIndexOf;
var
  ReturnValue: Integer;
  S: string;
begin
  S := 'Not to be found';
  ReturnValue := FFastLookupStringList.IndexOf(S);
  CheckEquals(-1, ReturnValue, 'IndexOf Not to be found');
  S := 'Original Third';
  ReturnValue := FFastLookupStringList.IndexOf(S);
  CheckEquals(2, ReturnValue, 'IndexOf Original Third');
  S := 'Original third';  // Differs in case
  ReturnValue := FFastLookupStringList.IndexOf(S);
  CheckEquals(2, ReturnValue, 'IndexOf Original third');
  // Change to case sensitive
  FFastLookupStringList.CaseSensitive := True;
  ReturnValue := FFastLookupStringList.IndexOf(S);
  CheckEquals(-1, ReturnValue, 'IndexOf Original third (CaseSensitive)');
end;

procedure TestTFastLookupStringList.TestPut;
begin
  CheckEquals('Original Third', FFastLookupStringList[2], 'Value before Put');
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf before Put');
  CheckEquals(5, FFastLookupStringList.Count, 'Count before Put');
  // Change to new value (one that didn't exist before)
  FFastLookupStringList[2] := 'New Third';
  CheckEquals('New Third', FFastLookupStringList[2], 'Value after Put');
  CheckEquals(-1, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf old after Put');
  CheckEquals(2, FFastLookupStringList.IndexOf('New Third'), 'IndexOf new after Put');
  CheckEquals(5, FFastLookupStringList.Count, 'Count after Put');
  // Change to existing value (one that already exist somewhere else in the list)
  FFastLookupStringList[0] := 'New Third';
  CheckEquals('New Third', FFastLookupStringList[0], 'Value 1 after Put2');
  CheckEquals('New Third', FFastLookupStringList[2], 'Value 2 after Put2');
  CheckEquals(-1, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf old after Put2');
  CheckTrue(FFastLookupStringList.IndexOf('New Third') in [0, 2], 'IndexOf new after Put2');  // Either 0 or 2 is fine
  CheckEquals(0, FFastLookupStringList.IndexOf('New Third'), 'Stricter IndexOf new after Put2');  // Only 0 is fine for full TStringList compatibility
  CheckEquals(5, FFastLookupStringList.Count, 'Count after Put2');
end;

procedure TestTFastLookupStringList.TestInsert;
begin
  CheckEquals('Original Third', FFastLookupStringList[2], 'Value before Insert');
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf before Insert');
  CheckEquals(5, FFastLookupStringList.Count, 'Count before Insert');
  // Insert new value (one that didn't exist in the list before)
  FFastLookupStringList.Insert(2, 'New Third');
  CheckEquals('New Third', FFastLookupStringList[2], 'Value after Insert');
  CheckEquals(5, FFastLookupStringList.IndexOf('Original Fifth'), 'IndexOf after Insert');
  CheckEquals(3, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf old after Insert');
  CheckEquals(2, FFastLookupStringList.IndexOf('New Third'), 'IndexOf new after Insert');
  CheckEquals(6, FFastLookupStringList.Count, 'Count after Insert');
  // Insert duplicate value at same place
  FFastLookupStringList.Insert(2, 'Original Second');
  CheckEquals('Original Second', FFastLookupStringList[1], 'Value after Insert Dup');  // Both here
  CheckEquals('Original Second', FFastLookupStringList[2], 'Value after Insert Dup');  // and here (now, too)
  CheckEquals('New Third', FFastLookupStringList[3], 'Value after Insert Dup');
  CheckEquals(1, FFastLookupStringList.IndexOf('Original Second'), 'IndexOf new after Insert Dup');  // 1 is right, becuase 'Original Second' is there, *too*
  CheckEquals(6, FFastLookupStringList.IndexOf('Original Fifth'), 'IndexOf after Insert Dup');
  CheckEquals(4, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf old after Insert Dup');
  CheckEquals(3, FFastLookupStringList.IndexOf('New Third'), 'IndexOf after Insert Dup');
  CheckEquals(7, FFastLookupStringList.Count, 'Count after Insert Dup');
  // Insert duplicate value at other place
  FFastLookupStringList.Insert(6, 'Original Second');
  CheckEquals('Original Second', FFastLookupStringList[1], 'Value after Insert Dup');  // Both here
  CheckEquals('Original Second', FFastLookupStringList[2], 'Value after Insert Dup');  // and here
  CheckEquals('Original Second', FFastLookupStringList[6], 'Value after Insert Dup2'); // and now also here.
  CheckEquals('New Third', FFastLookupStringList[3], 'Value after Insert Dup2');
  CheckEquals(1, FFastLookupStringList.IndexOf('Original Second'), 'IndexOf new after Insert Dup2');  // 1 is right, becuase 'Original Second' is there, *too*
  CheckEquals(7, FFastLookupStringList.IndexOf('Original Fifth'), 'IndexOf after Insert Dup2');
  CheckEquals(4, FFastLookupStringList.IndexOf('Original Third'), 'IndexOf old after Insert Dup2');
  CheckEquals(3, FFastLookupStringList.IndexOf('New Third'), 'IndexOf after Insert Dup2');
  CheckEquals(8, FFastLookupStringList.Count, 'Count after Insert Dup2');

  // Delete first one, check that IndexOf returns next one now (which happens to be at index 1, still)
  FFastLookupStringList.Delete(1);
  CheckEquals('Original Second', FFastLookupStringList[1], 'A After Insert+Delete 1');  // The one shifted left one step by Delete
  CheckEquals('New Third', FFastLookupStringList[2], 'B After Insert+Delete 1');
  CheckEquals('Original Second', FFastLookupStringList[5], 'C After Insert+Delete 1');  // The other one shifted left one step by Delete
  CheckEquals(1, FFastLookupStringList.IndexOf('Original Second'), 'D After Insert+Delete 1');  // 1 is right, becuase 'Original Second' is there, *too*
  CheckEquals(6, FFastLookupStringList.IndexOf('Original Fifth'), 'E After Insert+Delete 1');
  CheckEquals(3, FFastLookupStringList.IndexOf('Original Third'), 'F After Insert+Delete 1');
  CheckEquals(2, FFastLookupStringList.IndexOf('New Third'), 'G After Insert+Delete 1');
  CheckEquals(7, FFastLookupStringList.Count, 'H After Insert+Delete 1');
  // Delete second one, check that IndexOf returns next one now (which should be at index 4 now, no longer at 1)
  FFastLookupStringList.Delete(1);
  CheckEquals('New Third', FFastLookupStringList[1], 'A After Insert+Delete 2');
  CheckEquals('Original Second', FFastLookupStringList[4], 'B After Insert+Delete 2');  // The one shifted left one step by Delete
  CheckEquals(4, FFastLookupStringList.IndexOf('Original Second'), 'C After Insert+Delete 2');  // Now there should be only one 'Original Second' left, at index 4
  CheckEquals(5, FFastLookupStringList.IndexOf('Original Fifth'), 'D After Insert+Delete 2');
  CheckEquals(2, FFastLookupStringList.IndexOf('Original Third'), 'E After Insert+Delete 2');
  CheckEquals(1, FFastLookupStringList.IndexOf('New Third'), 'F After Insert+Delete 2');
  CheckEquals(6, FFastLookupStringList.Count, 'G After Insert+Delete 2');
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTFastLookupStringList.Suite);
end.

