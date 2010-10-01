use v6;

use ABC::Duration;

class ABC::Stem does ABC::Duration {
    has @.notes;
    
    method new(@notes) {
        fail "Stem must have at least one note" if +@notes == 0;
        self.bless(*, :@notes, :ticks(@notes>>.ticks.max));
    }
}
