use v6;

use ABC::Duration;

class ABC::Note does ABC::Duration {
    has $.pitch;
    has $.is-tie;
    
    method new($pitch, ABC::Duration $duration, $is-tie) {
        say :$duration.perl;
        self.bless(*, :$pitch, :ticks($duration.ticks), :$is-tie);
    }
}
