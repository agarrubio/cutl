# cutl
cut lines from file

## Motivation
There is no GNU tool specifically designed to extract lines from file by number. I find **sed** too complicated for this simple task. On the other end, **head** and **tail** are not versatile enough. **cutl** is written in **Perl** and takes many ideas from it (I.E. negative numbers count from the end of file, ellipsis '`..`' create ranges, etc). **cutl** follows the **UNIX** philosophy or doing one thing, and doing it well. **cutl** isn't superfast, but tries to be fast enough, even with big files.

## Installation
Just move the script cut_lines.pl somewhere in your path (maybe $HOME/bin), and add an alias in your '.bashrc'
```
alias cutl=cut_lines.pl
```
or
```
alias cutl="cut_lines.pl -z"  To count lines from zero, instead of one.
```
## Usage
**cutl** has a short help (`cutl -h`). This would be a simple use example:
```
 # Extract range 0 to 3, lines 8, 6, and range -5 to end (last 5 lines of file).
 %> seq 1 15 | cutl -l..3,8,6,-5..    
```
Negate the list with `-v`:
```
# Extract all lines **except** range 2 to 5, and lines 8 and 11
%> seq 1 15 | cutl -v -l2..5,8,11      
```
Read list from a file with `-f`:
```
%> cat mylist.txt
6,11 9..12
6 8
# Extract lines 6, 11, range 9 to 12, lines 6, 8
%> seq 1 15 | cutl -f mylist.txt      
```
Sample random lines with `-s` (sorted) or `-S` (unsorted):
```
# Extract 20 random lines
%> seq 1 1000 | cutl -s 20
```
## Bugs
I would be grateful if you tell me of any bugs or suggestions by raising an Issue.
