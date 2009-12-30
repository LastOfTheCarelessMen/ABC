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
g>ecg ec e/=f/g/e/ | d/c/B/A/ Gd BG B/c/d/B/ | 
g/f/e/d/ c/d/e/f/ gc e/f/g/e/ | dB/A/ gB +trill+A2 +trill+e2 :|»;

my $match = $abc ~~ m/ <ABC::tune> /;

die "Tune not matched\n" unless $match ~~ Match;

my @notes = gather for $match<ABC::tune><music><line_of_music> -> $line
{
    for $line<bar> -> $bar
    {
        for $bar<element>
        {
            when .<broken_rhythm> { take .<broken_rhythm><note>[0]; take .<broken_rhythm><note>[1]; }
            when .<note>          { take .<note>; }
        }
    }
}

sub apply_key_signature(%key_signature, $pitch)
{
    my $resulting_note = "";
    if $pitch<accidental>
    {
        $resulting_note ~= $pitch<accidental>.Str;
    }
    else
    {
        $resulting_note ~= %key_signature{$pitch<basenote>.uc} 
                if (%key_signature.exists($pitch<basenote>.uc));
    }
    $resulting_note ~= $pitch<basenote>;
    $resulting_note ~= $pitch<octave> if $pitch<octave>;
    return $resulting_note;
}

my %header = header_hash($match<ABC::tune><header>);
my %key_signature = key_signature(%header<K>);

@notes.map({say .<pitch> ~ " => " ~ apply_key_signature(%key_signature, .<pitch>)});
