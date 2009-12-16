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


done_testing;