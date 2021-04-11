# Git pre-commit hook to remove ExplicitXxxx from Delphi .DFM files

This is a pre-commit hook for git to remove ExplicitXxxx properties from Delphi .DFM files.

Delphi has an annoying habit of modifying the ExplicitLeft/ExplicitTop/ExplicitWidth/ExplicitHeight properties in .DFM files by itself, when no real changes have been made. This clutters git history (unless one cleans up the DFM file before every commit).

I made this pre-commit hook script for git, that automatically removes all those properties from modified .DFM files.

The point of those properties was to remember the original (manually designed) size and position for components (typically panels), so that when the component's actual size or position has changed because of Align := something (e.g Align = alClient), and then some time later Align is changed back to Align := alNone, it should get its original size again. This feature is really not much needed. The only drawback of removing the properties is that after changing back to Align := alNone, the component gets some other size. It doesn't really matter. The cluttering of git history is a much more real problem.

## To use this script:

Save the file pre-commit (named exactly like that, with no file name extension) to the .git/hooks directory in your repository. (The folder .git is normally hidden.) That is all.