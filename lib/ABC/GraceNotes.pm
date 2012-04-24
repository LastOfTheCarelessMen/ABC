use v6;

class ABC::GraceNotes {
    has $.acciaccatura;
    has @.notes;
    
    method new($acciaccatura, @notes) {
        die "GraceNotes must have at least one note" if +@notes == 0;
        self.bless(*, :$acciaccatura, :@notes);
    }
}
