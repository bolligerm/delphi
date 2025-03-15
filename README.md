# delphi

Delphi utilities

This is a collection of various Delphi programming utilities. I hope you find them useful.

**TFastLookupStringList** – has the exact same functionality as a TStringList,
but does fast lookups (IndexOf) even if it is not sorted.
It accomplishes this by using an internal dictionary.

It is most useful for stringlists with many items (at least 100 items
or more, but most notably useful with, say, tens of thousands of items).
This class uses its internal dictionary only when Sorted = False.
When Sorted = True, it handles everything using TStringList's original methods.

It should work on all versions of Delphi that support generics 
(has been tested on Delphi XE2, 10.2 Tokyo, 10.4 Sydney, 11.3 Alexandria and 12.3 Athens).