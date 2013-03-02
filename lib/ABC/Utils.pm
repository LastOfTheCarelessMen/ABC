use v6;
use ABC::Grammar;

package ABC::Utils {
    sub ElementToStr($element-pair) is export { 
        given $element-pair.key {
            when "gracing" {
                given $element-pair.value {
                    when '.' | '~' { $element-pair.value; }
                    '+' ~ $element-pair.value ~ '+';
                }
            }
            when "inline_field" { '[' ~ $element-pair.value.key ~ ':' ~ $element-pair.value.value ~ ']'; }
            when "chord_or_text" { 
                $element-pair.value.map({
                    when Str { '"' ~ $_ ~ '"'; }
                    ~$_; 
                }).join('') ; 
            }
            when "endline" { "\n"; }
            ~$element-pair.value;
        }
    }

    sub key_signature($key_signature_name) is export
    {
        my %keys = (
            'C' => 0,
            'G' => 1,
            'D' => 2,
            'A' => 3,
            'E' => 4,
            'B' => 5,
            'F' => -1,
        );

        my $match = ABC::Grammar.parse($key_signature_name, :rule<key>);
        # say :$match.perl;
        die "Illegal key signature\n" unless $match;
        fail unless $match<key-def>;
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
        my %hash;

        given $sharps {
            when 1..7   { for ^$sharps -> $i { %hash{@sharp_notes[$i]} = "^"; } }
            when -7..-1 { for ^(-$sharps) -> $i { %hash{@sharp_notes[6-$i]} = "_"; } }
        }

        if $match<key-def><global-accidental> {
            for $match<key-def><global-accidental> -> $ga {
                %hash{$ga<basenote>.uc} = ~$ga<accidental>;
            }
        }
        
        return %hash;
    }

    sub apply_key_signature(%key_signature, $pitch) is export
    {
        my $resulting_note = "";
        if $pitch<accidental>
        {
            $resulting_note ~= $pitch<accidental>.Str;
        }
        else
        {
            if %key_signature.exists($pitch<basenote>.uc) {
                $resulting_note ~= %key_signature{$pitch<basenote>.uc};
            }
        }
        $resulting_note ~= $pitch<basenote>.Str;
        $resulting_note ~= $pitch<octave>.Str if $pitch<octave>;
        return $resulting_note;
    }

    sub is-a-power-of-two($n) is export {
        if $n ~~ Rat {
            is-a-power-of-two($n.numerator) && is-a-power-of-two($n.denominator);
        } else {
            !($n +& ($n - 1));
        }
    }

    my %notename-to-ordinal = (
        C => 0,
        D => 2,
        E => 4,
        F => 5,
        G => 7,
        A => 9,
        B => 11,
        c => 12,
        d => 14,
        e => 16,
        f => 17,
        g => 19,
        a => 21,
        b => 23
    );
    
    sub pitch-to-ordinal(%key, $accidental, $basenote, $octave) is export {
        my $ord = %notename-to-ordinal{$basenote};
        given $accidental || %key{$basenote.uc} || "" {
            when /^ "^"+ $/ { $ord += $_.chars; }
            when /^ "_"+ $/ { $ord -= $_.chars; }
        }
        given $octave {
            when /^ "'"+ $/ { $ord += $_.chars * 12}
            when /^ ","+ $/ { $ord -= $_.chars * 12}
            when "" { }
            die "Unable to recognize octave $octave";
        }
        $ord;
    }

    sub ordinal-to-pitch(%key, $basenote, $ordinal) is export {
        my $octave = 0;
        my $working-ordinal = %notename-to-ordinal{$basenote.uc};
        while $ordinal + 5 < $working-ordinal {
            $working-ordinal -= 12;
            $octave -= 1;
        }
        while $working-ordinal + 5 < $ordinal {
            $working-ordinal += 12;
            $octave += 1;
        }
        
        my $key-accidental = %key{$basenote.uc} || "=";
        my $working-accidental;
        given $ordinal - $working-ordinal {
            when -2 { $working-accidental = "__"; }
            when -1 { $working-accidental = "_"; }
            when 0  { $working-accidental = "="; }
            when 1  { $working-accidental = "^"; }
            when 2  { $working-accidental = "^^"; }
            die "Too far away from note: $ordinal vs $working-ordinal";
        }
        if $key-accidental eq $working-accidental {
            $working-accidental = "";
        }
        if $octave > 0 {
            ($working-accidental, $basenote.lc, "'" x ($octave - 1));
        } else {
            ($working-accidental, $basenote.uc, "," x -$octave);
        }
    }
}


