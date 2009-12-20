use v6;
use Test;
use ABC;

plan *;

{
    my $match = "^A," ~~ m/ <ABC::pitch> /;
    isa_ok $match, Match, '"^A," is a pitch';
    is $match<ABC::pitch><basenote>, "A", '"^A," has base note A';
    is $match<ABC::pitch><octave>, ",", '"^A," has octave ","';
    is $match<ABC::pitch><accidental>, "^", '"^A," has accidental "#"';
}

{
    my $match = "_B" ~~ m/ <ABC::pitch> /;
    isa_ok $match, Match, '"_B" is a pitch';
    is $match<ABC::pitch><basenote>, "B", '"_B" has base note B';
    is $match<ABC::pitch><octave>, "", '"_B" has octave ""';
    is $match<ABC::pitch><accidental>, "_", '"_B" has accidental "_"';
}

{
    my $match = "C''" ~~ m/ <ABC::pitch> /;
    isa_ok $match, Match, '"note" is a pitch';
    is $match<ABC::pitch><basenote>, "C", '"note" has base note C';
    is $match<ABC::pitch><octave>, "''", '"note" has octave two-upticks';
    is $match<ABC::pitch><accidental>, "", '"note" has accidental ""';
}

{
    my $match = "=d,,," ~~ m/ <ABC::pitch> /;
    isa_ok $match, Match, '"=d,,," is a pitch';
    is $match<ABC::pitch><basenote>, "d", '"=d,,," has base note d';
    is $match<ABC::pitch><octave>, ",,,", '"=d,,," has octave ",,,"';
    is $match<ABC::pitch><accidental>, "=", '"=d,,," has accidental "="';
}

{
    my $match = "^^e2" ~~ m/ <ABC::note> /;
    isa_ok $match, Match, '"^^e2" is a note';
    is $match<ABC::note><pitch><basenote>, "e", '"^^e2" has base note e';
    is $match<ABC::note><pitch><octave>, "", '"^^e2" has octave ""';
    is $match<ABC::note><pitch><accidental>, "^^", '"^^e2" has accidental "^^"';
    is $match<ABC::note><note_length>, "2", '"^^e2" has note length 2';
}

{
    my $match = "__f'/" ~~ m/ <ABC::note> /;
    isa_ok $match, Match, '"__f/" is a note';
    is $match<ABC::note><pitch><basenote>, "f", '"__f/" has base note f';
    is $match<ABC::note><pitch><octave>, "'", '"__f/" has octave tick';
    is $match<ABC::note><pitch><accidental>, "__", '"__f/" has accidental "__"';
    is $match<ABC::note><note_length>, "/", '"__f/" has note length /';
}

{
    my $match = "G,2/3" ~~ m/ <ABC::note> /;
    isa_ok $match, Match, '"G,2/3" is a note';
    is $match<ABC::note><pitch><basenote>, "G", '"G,2/3" has base note G';
    is $match<ABC::note><pitch><octave>, ",", '"G,2/3" has octave ","';
    is $match<ABC::note><pitch><accidental>, "", '"G,2/3" has no accidental';
    is $match<ABC::note><note_length>, "2/3", '"G,2/3" has note length 2/3';
}

{
    my $match = "z2/3" ~~ m/ <ABC::rest> /;
    isa_ok $match, Match, '"z2/3" is a rest';
    is $match<ABC::rest><rest_type>, "z", '"z2/3" has base rest z';
    is $match<ABC::rest><note_length>, "2/3", '"z2/3" has note length 2/3';
}

{
    my $match = "y/3" ~~ m/ <ABC::rest> /;
    isa_ok $match, Match, '"y/3" is a rest';
    is $match<ABC::rest><rest_type>, "y", '"y/3" has base rest y';
    is $match<ABC::rest><note_length>, "/3", '"y/3" has note length 2/3';
}

{
    my $match = "x" ~~ m/ <ABC::rest> /;
    isa_ok $match, Match, '"x" is a rest';
    is $match<ABC::rest><rest_type>, "x", '"x" has base rest x';
    is $match<ABC::rest><note_length>, "", '"x" has no note length';
}

{
    my $match = "+trill+" ~~ m/ <ABC::element> /;
    isa_ok $match, Match, '"+trill+" is an element';
    is $match<ABC::element><gracing>, "+trill+", '"+trill+" gracing is +trill+';
}

{
    my $match = "z/" ~~ m/ <ABC::element> /;
    isa_ok $match, Match, '"z/" is an element';
    is $match<ABC::element><rest><rest_type>, "z", '"z/" has base rest z';
    is $match<ABC::element><rest><note_length>, "/", '"z/" has length "/"';
}

{
    my $match = "_D,5/4" ~~ m/ <ABC::element> /;
    isa_ok $match, Match, '"_D,5/4" is an element';
    is $match<ABC::element><note><pitch><basenote>, "D", '"_D,5/4" has base note D';
    is $match<ABC::element><note><pitch><octave>, ",", '"_D,5/4" has octave ","';
    is $match<ABC::element><note><pitch><accidental>, "_", '"_D,5/4" is flat';
    is $match<ABC::element><note><note_length>, "5/4", '"_D,5/4" has note length 5/4';
}

{
    my $match = "A>^C'" ~~ m/ <ABC::broken_rhythm> /;
    isa_ok $match, Match, '"A>^C" is a broken rhythm';
    is $match<ABC::broken_rhythm><note>[0]<pitch><basenote>, "A", 'first note is A';
    is $match<ABC::broken_rhythm><note>[0]<pitch><octave>, "", 'first note has no octave';
    is $match<ABC::broken_rhythm><note>[0]<pitch><accidental>, "", 'first note has no accidental';
    is $match<ABC::broken_rhythm><note>[0]<note_length>, "", 'first note has no length';
    is $match<ABC::broken_rhythm><broken_rhythm_bracket>, ">", 'angle is >';
    is $match<ABC::broken_rhythm><note>[1]<pitch><basenote>, "C", 'second note is C';
    is $match<ABC::broken_rhythm><note>[1]<pitch><octave>, "'", 'second note has octave tick';
    is $match<ABC::broken_rhythm><note>[1]<pitch><accidental>, "^", 'second note is sharp';
    is $match<ABC::broken_rhythm><note>[1]<note_length>, "", 'second note has no length';
}

{
    my $match = "d'+p+<<<+accent+_B" ~~ m/ <ABC::broken_rhythm> /;
    isa_ok $match, Match, '"d+p+<<<+accent+_B" is a broken rhythm';
    given $match<ABC::broken_rhythm>
    {
        is .<note>[0]<pitch><basenote>, "d", 'first note is d';
        is .<note>[0]<pitch><octave>, "'", 'first note has an octave tick';
        is .<note>[0]<pitch><accidental>, "", 'first note has no accidental';
        is .<note>[0]<note_length>, "", 'first note has no length';
        is .<g1>[0], "+p+", 'first gracing is +p+';
        is .<broken_rhythm_bracket>, "<<<", 'angle is <<<';
        is .<g2>[0], "+accent+", 'second gracing is +accent+';
        is .<note>[1]<pitch><basenote>, "B", 'second note is B';
        is .<note>[1]<pitch><octave>, "", 'second note has no octave';
        is .<note>[1]<pitch><accidental>, "_", 'second note is flat';
        is .<note>[1]<note_length>, "", 'second note has no length';
    }
}

for ':|:', '|:', '|', ':|', '::'  
{
    my $match = $_ ~~ m/ <ABC::barline> /;
    isa_ok $match, Match, "barline $_ recognized";
    is $match<ABC::barline>, $_, "barline $_ is correct";
}

{
    my $match = "g>ecgece/f/g/e/|" ~~ m/ <ABC::bar> /;
    isa_ok $match, Match, 'bar recognized';
    is $match<ABC::bar>, "g>ecgece/f/g/e/|", "Entire bar was matched";
    is $match<ABC::bar><element>.map(~*), "g>e c g e c e/ f/ g/ e/", "Each element was matched";
    is $match<ABC::bar><barline>, "|", "Barline was matched";
}

{
    my $match = "g>ecg ec e/f/g/e/ |" ~~ m/ <ABC::bar> /;
    isa_ok $match, Match, 'bar recognized';
    is $match<ABC::bar>, "g>ecg ec e/f/g/e/ |", "Entire bar was matched";
    is $match<ABC::bar><element>.map(~*), "g>e c g   e c   e/ f/ g/ e/  ", "Each element was matched";
    is $match<ABC::bar><barline>, "|", "Barline was matched";
}

{
    my $line = "g>ecg ec e/f/g/e/ | d/c/B/A/ Gd BG B/c/d/B/ |";
    my $match = $line ~~ m/ <ABC::line_of_music> /;
    isa_ok $match, Match, 'line of music recognized';
    is $match<ABC::line_of_music>, $line, "Entire line was matched";
    is $match<ABC::line_of_music><bar>[0], "g>ecg ec e/f/g/e/ |", "First bar is correct";
    is $match<ABC::line_of_music><bar>[1], " d/c/B/A/ Gd BG B/c/d/B/ |", "Second bar is correct";
    # say $match<ABC::line_of_music>.perl;
}

{
    my $line = "|A/B/c/A/ c>d e>deg | dB/A/ gB +trill+A2 +trill+e2 ::";
    my $match = $line ~~ m/ <ABC::line_of_music> /;
    isa_ok $match, Match, 'line of music recognized';
    is $match<ABC::line_of_music>, $line, "Entire line was matched";
    is $match<ABC::line_of_music><bar>[0], "A/B/c/A/ c>d e>deg |", "First bar is correct";
    is $match<ABC::line_of_music><bar>[1], " dB/A/ gB +trill+A2 +trill+e2 ::", "Second bar is correct";
    is $match<ABC::line_of_music><barline>, "|", "Initial barline matched";
    # say $match<ABC::line_of_music>.perl;
}

{
    my $music = q«A/B/c/A/ +trill+c>d e>deg | GG +trill+B>c d/B/A/G/ B/c/d/B/ |
    A/B/c/A/ c>d e>deg | dB/A/ gB +trill+A2 +trill+e2 ::
    g>ecg ec e/f/g/e/ | d/c/B/A/ Gd BG B/c/d/B/ | 
    g/f/e/d/ c/d/e/f/ gc e/f/g/e/ | dB/A/ gB +trill+A2 +trill+e2 :|»;
    my $match = $music ~~ m/ <ABC::music> /;
    isa_ok $match, Match, 'music recognized';
    is $match<ABC::music><line_of_music>.elems, 4, "Four lines matched";
}

{
    my $music = q«X:64
T:Cuckold Come Out o' the Amrey
S:Northumbrian Minstrelsy
M:4/4
L:1/8
K:D
»;
    my $match = $music ~~ m/ <ABC::header> /;
    isa_ok $match, Match, 'header recognized';
    is $match<ABC::header><header_field>.elems, 6, "Six fields matched";
    is $match<ABC::header><header_field>.map(*.<header_field_name>), "X T S M L K", "Got the right field names";
}

{
    my $music = q«X:64
T:Cuckold Come Out o' the Amrey
S:Northumbrian Minstrelsy
M:4/4
L:1/8
K:D
A/B/c/A/ +trill+c>d e>deg | GG +trill+B>c d/B/A/G/ B/c/d/B/ |
A/B/c/A/ c>d e>deg | dB/A/ gB +trill+A2 +trill+e2 ::
g>ecg ec e/f/g/e/ | d/c/B/A/ Gd BG B/c/d/B/ | 
g/f/e/d/ c/d/e/f/ gc e/f/g/e/ | dB/A/ gB +trill+A2 +trill+e2 :|
»;
    my $match = $music ~~ m/ <ABC::tune> /;
    isa_ok $match, Match, 'tune recognized';
    given $match<ABC::tune><header>
    {
        is .<header_field>.elems, 6, "Six fields matched";
        is .<header_field>.map(*.<header_field_name>), "X T S M L K", "Got the right field names";
    }
    is $match<ABC::tune><music><line_of_music>.elems, 4, "Four lines matched";
    say $match;
}

done_testing;