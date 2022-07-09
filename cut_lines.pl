#!env perl
use strict;
use warnings;
use List::Util qw(min max);
use Getopt::Std;

my(%opts,$tmp,$ln,$is_sorted,$min_line,$max_line);
getopts("hbzvl:f:s:", \%opts) or help();
$opts{h} && help();
if( -t STDIN and not @ARGV) {help()};

# ======================  main =======================

$opts{f}  && read_list(); # fills $opts{l} from file $opts{f};
$opts{s}  && sample();    # Sample lines. Does not return.
$opts{l} || help();

close_ranges();  # Clean list and closes open ranges,takes care of $opts{z}

# The following 3 subs implement different shortcuts, aplicable to simple cases
# If any succedes, it won't return: the script will finish.
try_upto();      # Behaves like head. Prints up to a line. -l..3 is like "head -4"
try_from();      # Behaves like tail -n+x. Prints from a line on. -l3.. is like "tail -n +4"
try_quick();     # Takes care of simple case (if line numbers increase, there are no negative 
                 # line numbers, nor open ranges, and no -v).

set_ln();        # Sets $ln (the number of lines in the file). If @ARGV is empty, saves STDIN 
                 # data in a file ($tmp), which becomes $ARGV[0]
parse_list();    # Converts negatives to positives. Sets $is_sorted, $min_line, $max_line

if( ! $is_sorted ){
    do_unsorted(); # Can write lines in arbitrary order
}else{
    do_sorted()    # Writes only in ascending order, but can negate list (-v)
}

# ======================  subs =======================
sub close_ranges{
    @ARGV<=1 or die "ERROR: use at most one file as argument.\n"; # TOO MANY FILES

    # remove spaces
    $opts{l}=~s/\s+//g; 
    
    # check valid characters
    $opts{l}=~ tr/0-9,.-//c and die "ERROR: invalid characters in list: $opts{l}\n";
    
    # remove repeated commas
    $opts{l}=~s/,+/,/g;
    # remove repeated '-'
    $opts{l}=~s/\-+/-/g;
    
    # start counting from one
    unless( $opts{z} ){
        $opts{l}=~s/(?<![-])(\d+)/one2zero($1)/eg;
    }
    
    # start open ranges
    $opts{l}=~ s{(?<=,)\.\.}{0..}g;
    $opts{l}=~ s{(?<=^)\.\.}{0..}g;
    
    # close open ranges
    $opts{l}=~ s{\.\.\,}{..-1,}g;
    $opts{l}=~ s{\.\.$}{..-1,}g;
    
    # one final comma
    $opts{l}=~s/(,*)$/,/;
    
    print STDERR "list is $opts{l}\n" if $opts{b};
}
sub sample{
    set_ln();
    my %lineno;
    $opts{s} = $ln if $ln <$opts{s};
    $opts{z} =1;
    while( scalar(%lineno)  < $opts{s}){
        $lineno{ int(rand($ln)) }++;
    }
    $opts{l}= join(',', sort {$a<=>$b} keys %lineno);
    try_quick();
}
sub one2zero{
    my $val=shift;
    $val == 0 && die "ERROR: line number == 0 while counting from one (see option -z).\n";
    return $val -1;
}
sub try_upto{
    $opts{l}=~m/^0\.\.(\d+),?$/ or return;
    print STDERR "Using UPTO. $opts{l}\n" if $opts{b};
    my $last = $1 +1;
    while(<>){
        print;
        last if $.== $last;
    }
    exit();
}
sub try_from{
    $opts{l}=~m/^(\d+)\.\.-1,?$/ or return;
    print STDERR "Using FROM. $opts{l}\n" if $opts{b};
    my $last = $1;
    while(<>){
        last if $.== $last;
    }
    while(<>){
        print
    }
    exit();
}

sub try_quick{
    
    $opts{v} && return;                           # reverse
    $opts{l}=~tr/-// && return;                   # has negatives;

    my $last=-1;
    my $line_cnt=0;
    
    # Check if list is grammatical and compatible with quick_listing
    foreach my $part ( split(',',$opts{l}) ){
        if( $part=~m/^\d+$/ ){
            return if $part <= $last;              # unsorted
            $last=$part;
            $line_cnt++;
        }elsif($part=~m/^(\d+)\.\.(\d+)$/){
            die "ERROR: Bad range $part\n" if $2<$1;   # BAD RANGE
            return if $1 <=$last;                  # unsorted
            $last=$1;
            return if $2 <=$last;                  # unsorted
            $last=$2;
            $line_cnt+=$2-$1+1;
        }elsif($part=~m/^(\d+)\.\.$/){
            return;                                # open range
        }else{
            die "ERROR: Bad specification in -v :$part\n" # INAVLID
        }
    }
    $line_cnt > 100000 && return ;                 # Hash would be too large
    
    
    print STDERR "Using QUICK. $opts{l}\n" if $opts{b};
    
    # expand $opts{l} into a hash of numbers
    my %num;
    foreach my $i ( eval $opts{l} ){
        $num{$i}++;
    }
    
    my($min,$max) = (sort {$a<=>$b} keys %num)[0,-1];
    while(<>){
        next if $. <= $min;
        print;
        last;
    }
    while(<>){
        my $j= $. -1;
        print if $num{$j};
        last if $j > $max;
    }
    
    exit();
}

sub do_sorted{
    my @mask;
    if( $opts{v} ){
        print STDERR "Using SORTED NEGATED. $opts{l}\n" if $opts{b};
        
        # create negative mask
        @mask = (1) x ( $ln );
        foreach my $i ( eval "$opts{l}" ){
            last if $i > $#mask;
            $mask[$i]=0;
        }
        # set $max_line to the last TRUE cell in $mask
        for(my $i= $#mask; $i>=0; $i--){
            next unless $mask[$i];
            $max_line=$i;
            last;
        }
        
        # report lines in mask
        my $j=0;
        while(<>){
            last if $j > $max_line;
            print if $mask[$j];
            $j++;
        }
        
        
    }else{
        print STDERR "Using SORTED. $opts{l}\n" if $opts{b};
        
        # create positive mask
        @mask = (0) x ($max_line +1 );
        foreach my $i ( eval $opts{l} ){
            last if $i > $#mask;
            $mask[$i]=1;
        }
        
        # report lines in mask
        my $j=0;
        while(<>){
            last if $j > $max_line;
            print if $mask[$j];
            $j++;
        }
    }
}

sub do_unsorted{
    $opts{v} and die "ERROR: Can't use option -v if lines are no ascending\n";
    
    print STDERR "Using UNSORTED. $opts{l}\n" if $opts{b};
    my @lines;
    
    # discard all lines before $min_line, leaving $lines[$i] undefined
    while(<>){
        my $j= $.-1;
        next if $j < $min_line;
        $lines[$j] = $_;
        last;
    }
    # read lines up to $max_line
    while(<>){
        my $j=$.-1;
        last if $j>$max_line;
        $lines[$j] = $_;
    }
    
    # expand $opts{l} and report corresponding lines
    foreach my $i ( eval $opts{l} ){
        print $lines[$i] if $i <= $#lines;
    }
}

sub parse_list{
    
    # convert negatives to positives
    $opts{l}=~ s{(\-\d+)}{$ln+$1}eg;
    
    # find BAD RANGES
    while( $opts{l}=~m{(\d+)\.\.(\d+)}g ){
        die "ERROR: Bad range $1..$2\n" if $1>$2;
    }
    $is_sorted=1;
    $max_line=-1;
    $min_line= 1e9;
    while( $opts{l}=~m{(\d+)}g ){
        $is_sorted = 0 if $1 <=$max_line;
        $max_line=$1 if $1 >$max_line;
        $min_line=$1 if $1 <$min_line;
    }
    $min_line = max(0,$min_line);
    $max_line = min($ln,$max_line) if $ln;
}

sub set_ln{
    # if data comes from STDIN, save it to file $tmp, and set it as $ARGV[0]
    unless( @ARGV ){
        $tmp="/var/tmp/stdin.$$";
        open(my $out, ">$tmp");
        while(<>){
            print {$out} $_;
        }
        close $out;
        $ARGV[0] = $tmp;
    }
    
    # use system to find number of lines
    $ln=`wc -l $ARGV[0]`;
    ($ln) = $ln=~m{^(\d+)};
}

sub read_list{
    $opts{l} and die "ERROR: Options -f and -l are not compatible\n";
    open(my $fh, "$opts{f}");
    $opts{l}='';
    while(<$fh>){
        next if /^#/;
        chomp;
        my $line = $_;
        s/\s+/,/g;
        tr/0-9,.-//c and die "ERROR: invalid characters in $opts{f}: $line\n";
        $opts{l}.=$_ . ',';
    }
}

sub END{
    system("rm $tmp") if $tmp;
}

sub help{ 
print STDERR "cutl -l list <file>\n"; 
die <<'ayuda'; 
cut lines from file as specified in list.

-h         This help
-l   list  Comma separated list of numbers.
             Negative numbers count from end of file: -5,-1
             Ranges are defined with two dots: '2..8' 
             Negatives are valid in ranges: '-10..8'
             A missing left value, implies 0 (first line of file)
             A missing right value, implies -1 (last line of file)
               ',..3' => ',0..3' and  '5..,' => '5..-1,'
             Thus -l..4 is like "head -5" and -l-4.. is like "tail -n4"
-v         Negate the list. Report lines NOT in list.
             Requires line numbers to be in strict ascending order.
-f  file   Read list from file (comma separated list of numbers)
             Whitespace (including newlines) are treated as commas.
-z         Count lines from zero. Default is count from 1.
-s  n      Sample n random lines. Note: Slow with large files
-b         Print some debugging information

Note on efficiency: 
Mainly, don't worry: modern computers are very fast!
However, in the worst case, lines are read into an array. For very large
  files, this can be slow and consume much RAM.
These conditions might (or not) decrease efficiency:
  1) list with negatives numbers, 2) unsorted line numbers (that do no 
  increase in monotonical order), 3) ranges that go to end-of-file, 4) 
  lists that implies > 100,000 lines, and 5) negation of list with -v
ayuda
}


