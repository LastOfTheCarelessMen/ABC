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
use ABC::Utils;
use ABC::Pitched;

sub transpose(Str $test, $pitch-changer) {
    my $match = ABC::Grammar.parse($test, :rule<element>, :actions(ABC::Actions.new));
    if $match {
        $match.ast.value.transpose($pitch-changer);
    }
}

sub up-octave($accidental, $basenote, $octave) {
    if $octave ~~ /","/ {
        return ($accidental, $basenote, $/.postmatch);
    } elsif $octave ~~ /"'"/ || $basenote ~~ /<lower>/ {
        return ($accidental, $basenote, $octave ~ "'");
    } else {
        return ($accidental, $basenote.lc, $octave);
    }
}

is transpose("A", &up-octave), "a", "Octave bump to A yields a";
is transpose("a", &up-octave), "a'", "Octave bump to a yields a'";
is transpose("a''", &up-octave), "a'''", "Octave bump to a'' yields a'''";
is transpose("A,", &up-octave), "A", "Octave bump to A, yields A";
is transpose("A,,", &up-octave), "A,", "Octave bump to A,, yields A,";


done;
