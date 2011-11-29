use v6;

grammar ABC::Grammar
{
    regex header_field_name { \w }
    regex header_field_data { \N* }
    regex header_field { ^^ <header_field_name> ':' \s* <header_field_data> $$ }
    regex header { [<header_field> \v+]+ }

    regex basenote { <[a..g]+[A..G]> }
    regex octave { "'"+ | ","+ }
    regex accidental { '^' | '^^' | '_' | '__' | '=' }
    regex pitch { <accidental>? <basenote> <octave>? }

    regex tie { '-' }
    regex number { <digit>+ }
    regex note_length_denominator { '/' <bottom=number>? }
    regex note_length { <top=number>? <note_length_denominator>? }
    regex mnote { <pitch> <note_length> <tie>? }
    regex stem { <mnote> | [ '[' <mnote>+ ']' ]  }
    
    regex rest_type { <[x..z]> }
    regex rest { <rest_type> <note_length> }
    
    regex slur_begin { '(' }
    regex slur_end { ')' }
    
    regex grace_note { <pitch> <note_length>? } # as mnote, but without tie
    regex grace_note_stem { <grace_note> | [ '[' <grace_note>+ ']' ]  }
    regex acciaccatura { '/' }
    regex grace_notes { '{' <acciaccatura>? <grace_note_stem>+ '}' }
    
    regex long_gracing_text { [<alpha> | '.']+ }
    regex long_gracing { '+' <long_gracing_text> '+' }
    regex gracing { '.' | '~' | <long_gracing> }
    
    regex spacing { \h+ }
    
    regex broken_rhythm_bracket { ['<'+ | '>'+] }
    regex b_elem { <gracing> | <grace_notes> | <slur_begin> | <slur_end> }
    regex broken_rhythm { <stem> <g1=b_elem>* <broken_rhythm_bracket> <g2=b_elem>* <stem> }
    
    regex t_elem { <gracing> | <grace_notes> | <broken_rhythm> | <slur_begin> | <slur_end> }
    # next line should work, but is NYI in Rakudo
    # regex tuple { '('(<digit>+) [<t_elem>* <stem>] ** { $0 } }
    # next block makes the most common case work
    regex tuplet { '(3' [<t_elem>* <stem>] ** 3 }
    
    regex nth_repeat_num { <digit>+ [[',' | '-'] <digit>+]* }
    regex nth_repeat_text { '"' .*? '"' }
    regex nth_repeat { '[' [ <nth_repeat_num> | <nth_repeat_text> ] }
    regex end_nth_repeat { ']' }
    
    regex inline_field { '[' (<alpha>) ':' (.*?) ']' }
    
    regex element { <broken_rhythm> | <stem> | <rest> | <tuplet> | <slur_begin> | <slur_end>
                    | <gracing> | <grace_notes> | <nth_repeat> | <end_nth_repeat>
                    | <spacing> | <inline_field> }
    
    regex barline { '||' | '|]' | ':|:' | '|:' | '|' | ':|' | '::' }
    
    regex bar { <element>+ <barline>? }
        
    regex line_of_music { <barline>? <bar>+ }
    
    regex music { [<line_of_music> \s*\v?]+ }
    
    regex tune { <header> <music> }
    
    regex tune_file { \s* [<tune> \s*]+ }
    
    regex key_sig { <basenote> ('#' | 'b')? \h* (\w*) }
    
    our sub key_signature($key_signature_name) is export
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
        my $lookup = [~] $match<basenote>.uc, $match[0];
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

    our sub apply_key_signature(%key_signature, $pitch)
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
}

sub header_hash($header_match)
{
    gather for $header_match<header_field>
    {
        take $_.<header_field_name>.Str => $_.<header_field_data>.Str;
    }
}

