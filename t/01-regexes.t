use v6;
use Test;
use ABC;

plan *;

{
    my $match = "^A," ~~ m/ <ABC::pitch> /;
    isa_ok $match, Match, '"^A," is a pitch';
    is $<ABC::pitch><basenote>, "A", '"^A," has base note A';
    is $<ABC::pitch><octave>, ",", '"^A," has octave ","';
    is $<ABC::pitch><accidental>, "^", '"^A," has accidental "#"';
}

done_testing;