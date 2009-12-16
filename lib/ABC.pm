use v6;

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
    regex note_length { [\d* ['/' \d*]? ] | '/' }
    regex note { <pitch> <note_length>? <tie>? }
    
    regex rest_type { <[x..z]> }
    regex rest { <rest_type> <note_length>? }
    
    regex gracing { '+' <alpha>+ '+' }
    
    regex broken_rhythm_bracket { ['<'+ | '>'+] }
    regex broken_rhythm { <note> <gracing>* <broken_rhythm_bracket> <gracing>* <note> }
    
    regex element { <note> | <broken_rhythm> | <rest> | <gracing> }
    
}

class ABCHeader
{
    
}

class ABCBody
{
    
}

class ABCTune
{
    has $.header;
    has $.body;
    
}