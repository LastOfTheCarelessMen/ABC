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
            when "chord_or_text" { '"' ~ $element-pair.value ~ '"'; }
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
        
        # say :$key_signature_name.perl;

        my $match = ABC::Grammar.parse($key_signature_name, :rule<key_sig>);
        # say :$match.perl;
        die "Illegal key signature\n" unless $match;
        my $lookup = $match<basenote>.uc ~ ($match[0] // "");
        # say :$lookup.perl;
        my $sharps = %keys{$lookup};

        # say :$sharps.perl;

        if ($match[1].defined) {
            given ~($match[1]) {
                when ""     { }
                when /^maj/ { }
                when /^ion/ { }
                when /^mix/ { $sharps -= 1; }
                when /^dor/ { $sharps -= 2; }
                when /^m/   { $sharps -= 3; }
                when /^aeo/ { $sharps -= 3; }
                when /^phr/ { $sharps -= 4; }
                when /^loc/ { $sharps -= 5; }
                when /^lyd/ { $sharps += 1; }
                default     { die "Unknown mode {$match[1]} requested"; }
            }
        }

        my @sharp_notes = <F C G D A E B>;
        my %hash;

        given $sharps {
            when 1..7   { for ^$sharps -> $i { %hash{@sharp_notes[$i]} = "^"; } }
            when -7..-1 { for ^(-$sharps) -> $i { %hash{@sharp_notes[6-$i]} = "_"; } }
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


