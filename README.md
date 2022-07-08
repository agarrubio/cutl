# cutl
cut lines from file

## Motivation
There is no GNU tool specifically designed to extract lines from file by number. I find **sed** too complicated for this simple task. On the other end, **head** and **tail** are not versatile enough. **cutl** is written in **Perl** and takes many ideas from it (I.E. negative numbers count from the end of file, ellipsis '`..`' create ranges, etc). **cutl** follows the **UNIX** philosophy or doing one thing, and doing it well. **cutl** isn't superfast, but tries to be fast enough, even with big files.

## Installation
Just move the script cut_lines.pl somewhere in your path (maybe $HOME/bin), and add an alias in your '.bashrc'
```
alias cutl=cut_lines.pl
```

## Usage
**cutl** has a short help (`cutl -h`). This would be a simple use example:
```
%> seq 1 15 | cutl -l..3,8,6,-5..     # print range 0 to 3, lines 8, 6, and range -5 to end (last 5 lines of file).
```
Negate the list with `-v`:
```
%> seq 1 15 | cutl -v -l..3,8,11      # print all lines except range 0 to 3, and lines 8 and 11
```
Give list in a file with `-f`:
```
%> cat mylist.txt
6,11 9..12
6 8
%> seq 1 15 | cutl -f mylist.txt      # print lines 6, 11, range 9 to 12, lines 6, 8
```
## Bugs
I would be grateful if you tell me of any bugs or suggestions by raising an Issue.
