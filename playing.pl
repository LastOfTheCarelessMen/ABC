use v6;

BEGIN { push @*INC, "lib" }
use ABC;

my $abc = q«X:64
T:Cuckold Come Out o' the Amrey
S:Northumbrian Minstrelsy
M:4/4
L:1/8
K:D
A/B/c/A/ +trill+c>d e>deg | GG +trill+B>c d/B/A/G/ B/c/d/B/ |
A/B/c/A/ c>d e>deg | dB/A/ gB +trill+A2 +trill+e2 ::
g>ecg ec e/f/g/e/ | d/c/B/A/ Gd BG B/c/d/B/ | 
g/f/e/d/ c/d/e/f/ gc e/f/g/e/ | dB/A/ gB +trill+A2 +trill+e2 :|»;

if $abc ~~ m/ <ABC::header> /
{
    for $<ABC::header><header_field> -> $line
    {
        say "header: {$line<header_field_name>}: {$line<header_field_data>}";
    }
}

if "^^A/3" ~~ m/ <ABC::note> /
{
    say $<ABC::note>.perl;
}
