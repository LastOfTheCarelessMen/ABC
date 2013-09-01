use v6;

use ABC::Duration;
use ABC::Pitched;

class ABC::Tuplet does ABC::Duration does ABC::Pitched {
    has $.tuple;
    has @.notes;
    
    method new($tuple, @notes) {
        die "Tuplet must have at least one note" if +@notes == 0;
        self.bless(:$tuple, :@notes, :ticks(2/$tuple * [+] @notes>>.ticks));
    }

    method Str() {
        "(" ~ $.tuple ~ @.notes.join("");
    }

    method transpose($pitch-changer) {
        ABC::Tuplet.new($.tuple, @.notes>>.transpose($pitch-changer));
    }
}
