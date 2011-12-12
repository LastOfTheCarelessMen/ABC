use v6;

class ABC::Chord {
    has $.main-note;
    has $.main-accidental;
    has $.main-type;
    has $.bass-note;
    has $.bass-accidental;

    method new($main-note, $main-accidental, $main-type, $bass-note, $bass-accidental) {
        self.bless(*, :$main-note, :$main-accidental, :$main-type, :$bass-note, :$bass-accidental);
    }

    method Str() {
        $.main-type ~ $.main-accidental ~ $.main-type ~ ($.bass-note ?? '/' ~ $.bass-note ~ $.bass-accidental !! "");
    }
}