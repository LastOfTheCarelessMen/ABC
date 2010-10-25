use v6;

use ABC::Duration;
use ABC::Note;
use ABC::Stem;

class ABC::BrokenRhythm does ABC::Duration {
    has $.stem1;
    has $.gracing1;
    has $.broken-rhythm;
    has $.gracing2;
    has $.stem2;
    
    method new($stem1, $gracing1, $broken-rhythm, $gracing2, $stem2) {
        self.bless(*, :$stem1, :$gracing1, :$broken-rhythm, :$gracing2, :$stem2, 
                   :ticks($stem1.ticks + $stem2.ticks));
    }

    my method broken-factor() {
        1 / 2 ** $.broken-rhythm.chars.Int;
    }
    
    my method broken-direction-forward() {
        $.broken-rhythm ~~ /\>/;
    }
    
    my multi sub new-rhythm(ABC::Note $note, $ticks) {
        ABC::Note.new($note.pitch, ABC::Duration.new(:$ticks), $note.is-tie);
    }

    my multi sub new-rhythm(ABC::Stem $stem, $ticks) {
        ABC::Stem.new($stem.notes.map({ new-rhythm($_, $ticks); }));
    }

    method effective-stem1() {
        new-rhythm($.stem1, self.broken-direction-forward ?? $.stem1.ticks * (2 - self.broken-factor)
                                                          !! $.stem1.ticks * self.broken-factor);
    }
    
    method effective-stem2() {
        new-rhythm($.stem2, self.broken-direction-forward ?? $.stem2.ticks * self.broken-factor
                                                          !! $.stem2.ticks * (2 - self.broken-factor));
    }
    
}
