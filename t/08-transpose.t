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
is transpose("a''2", &up-octave), "a'''2", "Octave bump to a'' yields a'''";
is transpose("A,-", &up-octave), "A-", "Octave bump to A, yields A";
is transpose("A,,", &up-octave), "A,", "Octave bump to A,, yields A,";
is transpose("[C,Eg]", &up-octave), "[Ceg']", "Octave bump to [C,Eg] yields [Ceg']";
is transpose("[C,Eg]", &up-octave), "[Ceg']", "Octave bump to [C,Eg] yields [Ceg']";
is transpose("(3C,Eg", &up-octave), "(3Ceg'", "Octave bump to (3C,Eg yields (3Ceg'";
is transpose("A<a", &up-octave), "a<a'", "Octave bump to A<a yields a<a'";
is transpose('{Bc}', &up-octave), '{bc\'}', "Octave bump to Bc yields bc'";


done;
