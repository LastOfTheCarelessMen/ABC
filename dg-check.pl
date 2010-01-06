use v6;

BEGIN { push @*INC, "lib" }
use ABC;

my @matches = $*IN.lines.join("\n").comb(m/ <ABC::tune> /, :match);

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

    my %header = header_hash(.<ABC::tune><header>);
    my %key_signature = key_signature(%header<K>);

    @notes.map({say .<pitch> ~ " => " ~ apply_key_signature(%key_signature, .<pitch>)});
}
