# cutl
cut lines from file

## Motivation
There is no GNU tool specically designed to extract lines from file by number. I find **sed** too complicated for this simple task. On the other end, **head** and **tail** are not versatile enough. **cutl** is written in **Perl** and takes many ideas from it (I.E. negative numbers count from the end of file, elipsis '`..`' create ranges, etc). **cutl** follows the **UNIX** phylosophy or doing one thing, and doing it well. **cutl** isn't superfast, but tries to be fast enough, even with big files.

## Installation
Just move the script cut_lines.pl somewhere in your path (maybe $HOME/bin), and add an alias to your '.bashrc'
```
alias cutl=cut_lines.pl
```

