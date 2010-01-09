use v6;

BEGIN { push @*INC, "lib" }
use ABC;

my @matches = $*IN.slurp.comb(m/ <ABC::tune> /, :match);

my %dg_notes = {
    'g' => 1,
    'a' => 1,
    'b' => 1,
    'c' => 1,
    'd' => 1,
    'e' => 1,
    '^f' => 1
}

for @matches {
    my %header = header_hash(.<ABC::tune><header>);
    say %header<T> ~ ":";

    my @notes = gather for .<ABC::tune><music><line_of_music> -> $line
    {
        for $line<bar> -> $bar
        {
            for $bar<element>
            {
                when .<broken_rhythm> { take .<broken_rhythm><note>[0]; take .<broken_rhythm><note>[1]; }
                when .<note>          { take .<note>; }
            }
        }
    }

    my %key_signature = key_signature(%header<K>);

    my @trouble = @notes.map({apply_key_signature(%key_signature, .<pitch>)}).grep({!%dg_notes.exists(lc($_))});
    say @trouble.perl;
}
