use v6;
use ABC::Grammar;

class ABC::KeyInfo {
    has %.key;
    has $.clef;
    
    method new($key-field, :$current-key-info) {
        my $match = ABC::Grammar.parse($key-field, :rule<key>);
        # say :$match.perl;
        die "Illegal key signature\n" unless $match;

        my %key-info;
        my $clef-info;
        if $current-key-info {
            %key-info = $current-key-info.key;
            $clef-info = $current-key-info.clef;
        }
        
        if $match<key-def> {
            %key-info = {};
            my %keys = (
                'C' => 0,
                'G' => 1,
                'D' => 2,
                'A' => 3,
                'E' => 4,
                'B' => 5,
                'F' => -1,
            );

            # say $match<key-def>.perl;
            my $lookup = $match<key-def><basenote>.uc;
            # say :$lookup.perl;
            my $sharps = %keys{$match<key-def><basenote>.uc};
            if $match<key-def><chord_accidental> {
                given ~$match<key-def><chord_accidental> {
                    when "#" { $sharps += 7; }
                    when "b" { $sharps -= 7; }
                }
            }

            if $match<key-def><mode> {
                given $match<key-def><mode>[0] {
                    when so .<major>      { }
                    when so .<ionian>     { }
                    when so .<mixolydian> { $sharps -= 1; }
                    when so .<dorian>     { $sharps -= 2; }
                    when so .<minor>      { $sharps -= 3; }
                    when so .<aeolian>    { $sharps -= 3; }
                    when so .<phrygian>   { $sharps -= 4; }
                    when so .<locrian>    { $sharps -= 5; }
                    when so .<lydian>     { $sharps += 1; }
                    default { die "Unknown mode $_ requested"; }
                }
            }

            my @sharp_notes = <F C G D A E B>;

            given $sharps {
                when 1..7   { for ^$sharps -> $i { %key-info{@sharp_notes[$i]} = "^"; } }
                when -7..-1 { for ^(-$sharps) -> $i { %key-info{@sharp_notes[6-$i]} = "_"; } }
            }

            if $match<key-def><global-accidental> {
                for $match<key-def><global-accidental> -> $ga {
                    %key-info{$ga<basenote>.uc} = ~$ga<accidental>;
                }
            }
        }
        
        if $match<clef> {
            $clef-info = ~($match<clef>[0]<clef-name> // $match<clef>[0]<clef-note>);
        }
        
        self.bless(*, :key(%key-info), :clef($clef-info));
    }
    
}