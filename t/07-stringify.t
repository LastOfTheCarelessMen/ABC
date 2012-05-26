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

my @simple-cases = ("a", "B,", "c'''", "^D2-", "_E,,/", "^^f/4", "=G3",
                    "[ceg]", "[D3/2d3/2]", "[A,2F2]",
                    "(3abc", "(5A/B/C/D/E/",
                    "a>b", "^c/4<B,,/4",
                    "(", ")");

for @simple-cases -> $test-case {
    my $match = ABC::Grammar.parse($test-case, :rule<element>, :actions(ABC::Actions.new));
    ok $match, "$test-case parsed";
    my $object = $match.ast.value;
    # say $object.perl;
    is ~$object, $test-case, "Stringified version matches";
}




done;