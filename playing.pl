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

sub key_signature($key_signature_name)
{
    my %keys = (
        'C' => 0,
        'G' => 1,
        'D' => 2,
        'A' => 3,
        'E' => 4,
        'B' => 5,
        'F#' => 6,
        'C#' => 7,
        'F' => -1,
        'Bb' => -2,
        'Eb' => -3,
        'Ab' => -4,
        'Db' => -5,
        'Gb' => -6,
        'Cb' => -7
    );
    
    $match = $key_signature_name ~~ m/ <ABC::basenote> ('#' | 'b')? (\w*) /;
    die "Illegal key signature\n" unless $match ~~ Match;
    say "$key_signature_name:";
    my $lookup = [~] $match<ABC::basenote>.uc, $match[0];
    
    my @sharps = <F C G D A E B>;
    my %hash = @sharps Z @sharps;
    
    given %keys{$lookup} {
        when 1..7   { for ^%keys{$lookup} -> $i { %hash{@sharps[$i]} = "^" ~ @sharps[$i]; } }
        when -7..-1 { for ^(-%keys{$lookup}) -> $i { %hash{@sharps[6-$i]} = "_" ~ @sharps[6-$i]; } }
    }

    say %hash.perl;
    
}

# @notes.map({.<pitch>.say});

key_signature("Abmix");
key_signature("Ab");
key_signature("Amix");