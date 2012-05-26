use v6;

use ABC::Duration;

class ABC::Tuplet does ABC::Duration {
    has $.tuple;
    has @.notes;
    
    method new($tuple, @notes) {
        die "Tuplet must have at least one note" if +@notes == 0;
        self.bless(*, :$tuple, :@notes, :ticks(2/$tuple * [+] @notes>>.ticks));
    }

    method Str() {
        "(" ~ $.tuple ~ @.notes.join("");
    }
}
