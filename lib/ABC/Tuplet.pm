use v6;

use ABC::Duration;
use ABC::Pitched;

class ABC::Tuplet does ABC::Duration does ABC::Pitched {
    has $.p;
    has $.q;
    has @.notes;
    
    multi method new($p, @notes) {
        my $q;
        given $p {
            when 3 | 6     { $q = 2; }
            when 2 | 4 | 8 { $q = 3; }
            default        { $q = 2; } # really need to know the time signature for this!
        }
        self.new($p, $q, @notes);
    }

    multi method new($p, $q, @notes) {
        die "Tuplet must have at least one note" if +@notes == 0;
        self.bless(:$p, :$q, :@notes, :ticks($q/$p * [+] @notes>>.ticks));
    }

    method Str() {
        # MUST: factor in $q when that has non-default values
        @.notes == $.p ?? "(" ~ $.p ~ @.notes.join("")
                       !! "(" ~ $.p ~ "::" ~ +@.notes ~ @.notes.join(""); 
    }

    method transpose($pitch-changer) {
        ABC::Tuplet.new($.tuple, @.notes>>.transpose($pitch-changer));
    }

    method tuple() { $.p; } # for backwards compatibility, probably needs to go in the long run
}
