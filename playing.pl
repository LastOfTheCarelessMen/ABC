use v6;

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

grammar ABC
{
    regex header_field_name { \w }
    regex header_field_data { \N* }
    regex header_field { ^^ <header_field_name> ':' \s* <header_field_data> $$ }
    regex header { [<header_field> \n]+ }

    regex basenote { <[a..g]+[A..G]> }
    regex octave { \'+ | \,+ }
    regex accidental { '^' | '^^' | '_' | '__' | '=' }
    regex pitch { <accidental>? <basenote> <octave>? }

    regex tie { '-' }
    regex note_length { [\d* ['/' \d*] ] | '/' }
    regex note { <pitch> <note_length>? <tie>? }
}

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
