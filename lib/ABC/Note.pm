use v6;

use ABC::Duration;

class ABC::Note does ABC::Duration {
    has $.accidental;
    has $.basenote;
    has $.octave;
    has $.is-tie;
    
    method new($accidental, $basenote, $octave, ABC::Duration $duration, $is-tie) {
        self.bless(*, :$accidental, :$basenote, :$octave, :ticks($duration.ticks), :$is-tie);
    }

    method pitch() {
        $.accidental ~ $.basenote ~ $.octave;
    }

    method Str() {
        $.pitch ~ self.duration-to-str ~ ($.is-tie ?? "-" !! "");
    }

    method perl() {
        "ABC::Note.new({ $.pitch.perl }, { $.ticks.perl }, { $.is-tie.perl })";
    }
}
