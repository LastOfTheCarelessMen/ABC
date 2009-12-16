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

regex abc_header_field_name { \w }
regex abc_header_field_data { \N* }
regex abc_header_field { ^^ <abc_header_field_name> ':' \s* <abc_header_field_data> $$ }
regex abc_header { [<abc_header_field> \n]+ }

regex abc_basenote { <[a..g]+[A..G]> }
regex abc_octave { \'+ | \,+ }
regex abc_accidental { '^' | '^^' | '_' | '__' | '=' }
regex abc_pitch { <abc_accidental>? <abc_basenote> <abc_octave>? }

regex abc_tie { '-' }
regex abc_note_length { [\d* ['/' \d*] ] | '/' }
regex abc_note { <abc_pitch> <abc_note_length>? <abc_tie>? }

if $abc ~~ m/ <abc_header> /
{
    for $<abc_header><abc_header_field> -> $line
    {
        say "header: {$line<abc_header_field_name>}: {$line<abc_header_field_data>}";
    }
}

if "^^A/3" ~~ m/ <abc_note> /
{
    say $<abc_note>.perl;
}
