use v6;
# use Grammar::Tracer;

grammar ABC::Grammar
{
    regex comment_line { ^^ \h* '%' \N* $$ }
    
    token header_field_name { \w }
    token header_field_data { \N* }
    token header_field { ^^ <header_field_name> ':' \s* <header_field_data> $$ }
    token header { [[<header_field> | <comment_line>] \v+]+ }

    token basenote { <[a..g]+[A..G]> }
    token octave { "'"+ | ","+ }
    token accidental { '^^' | '^' | '__' | '_' | '=' }
    token pitch { <accidental>? <basenote> <octave>? }

    token tie { '-' }
    token number { <digit>+ }
    token note_length_denominator { '/' <bottom=number>? }
    token note_length { <top=number>? <note_length_denominator>? }
    token mnote { <pitch> <note_length> <tie>? }
    token stem { <mnote> | [ '[' <mnote>+ ']' <note_length> <tie>? ]  }
    
    token rest_type { <[x..z]> }
    token rest { <rest_type> <note_length> }
    token multi_measure_rest { 'Z' <number> }
    
    token slur_begin { '(' }
    token slur_end { ')' }
    
    token grace_note { <pitch> <note_length> } # as mnote, but without tie
    token grace_note_stem { <grace_note> | [ '[' <grace_note>+ ']' ]  }
    token acciaccatura { '/' }
    token grace_notes { '{' <acciaccatura>? <grace_note_stem>+ '}' }
    
    token long_gracing_text { [<alpha> | '.' | ')' | '(']+ }
    token long_gracing { '+' <long_gracing_text> '+' }
    token gracing { '.' | '~' | <long_gracing> }
    
    token spacing { \h+ }
    
    token broken_rhythm_bracket { ['<'+ | '>'+] }
    token b_elem { <gracing> | <grace_notes> | <slur_begin> | <slur_end> }
    token broken_rhythm { <stem> <g1=b_elem>* <broken_rhythm_bracket> <g2=b_elem>* <stem> }
    
    token t_elem { <gracing> | <grace_notes> | <broken_rhythm> | <slur_begin> | <slur_end> }
    # next line should work, but is NYI in Rakudo/Niecza
    token tuplet { '('(<digit>+) {} [<t_elem>* <stem>] ** { +$0 } <slur_end>? }
    # next block makes the most common cases work
    # token tuplet { ['(3' [<t_elem>* <stem>] ** 3 <slur_end>? ] 
    #              | ['(4' [<t_elem>* <stem>] ** 4 <slur_end>? ]
    #              | ['(5' [<t_elem>* <stem>] ** 5 <slur_end>? ] }
    
    token nth_repeat_num { <digit>+ [[',' | '-'] <digit>+]* }
    token nth_repeat_text { '"' .*? '"' }
    token nth_repeat { ['[' [ <nth_repeat_num> | <nth_repeat_text> ]] | [<?after '|'> <nth_repeat_num>] }
    token end_nth_repeat { ']' }
    
    regex inline_field { '[' <alpha> ':' $<value>=[.*?] ']' }
    
    token chord_accidental { '#' | 'b' | '=' }
    token chord_type { [ <alpha> | <digit> | '+' | '-' ]+ }
    token chord_newline { '\n' | ';' }
    token chord { <mainnote=basenote> <mainaccidental=chord_accidental>? <maintype=chord_type>? 
                  [ '/' <bassnote=basenote> <bass_accidental=chord_accidental>? ]? <non_quote>* } 
    token non_quote { <-["]> }
    token text_expression { [ '^' | '<' | '>' | '_' | '@' ] <non_quote>+ }
    token chord_or_text { '"' [ <chord> | <text_expression> ] [ <chord_newline> [ <chord> | <text_expression> ] ]* '"' }
    
    token element { <broken_rhythm> | <stem> | <rest> | <tuplet> | <slur_begin> | <slur_end> 
                    | <multi_measure_rest>
                    | <gracing> | <grace_notes> | <nth_repeat> | <end_nth_repeat>
                    | <spacing> | <inline_field> | <chord_or_text> }
    
    token barline { '||' | '|]' | ':|:' | '|:' | '|' | ':|' | '::' | '||:' }
    
    token bar { <element>+ <barline>? }
        
    token line_of_music { <barline>? <bar>+ '\\'? }
    
    token interior_header_field_name { < K M L > }
    token interior_header_field_data { \N* }
    token interior_header_field { ^^ <interior_header_field_name> ':' \s* <interior_header_field_data> $$ }

    token music { [[<line_of_music> | <interior_header_field> | <comment_line> ] \s*]+ }
    
    token tune { <header> <music> }
    
    token tune_file { \s* [<tune> \s*]+ }
    
    token key_sig { <basenote> ('#' | 'b')? \h* (\w*) }
    
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

sub header_hash($header_match) #OK
{
    gather for $header_match<header_field>
    {
        take $_.<header_field_name>.Str => $_.<header_field_data>.Str;
    }
}

