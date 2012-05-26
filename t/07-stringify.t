use v6;
use Test;

use ABC::Grammar;
use ABC::Header;
use ABC::Tune;
use ABC::Duration;
use ABC::Note;
use ABC::Rest;
use ABC::Tuplet;
use ABC::BrokenRhythm;
use ABC::Chord;
use ABC::LongRest;
use ABC::GraceNotes;
use ABC::Actions;

my @simple-cases = ("a", "B,", "c'''", );

for @simple-cases -> $test-case {
    my $match = ABC::Grammar.parse($test-case, :rule<element>, :actions(ABC::Actions.new));
    ok $match, "$test-case parsed";
    my $object = $match.ast.value;
    say $object.perl;
    is ~$object, $test-case, "Stringified version matches";
}




done;