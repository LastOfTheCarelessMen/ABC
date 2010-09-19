use v6;
use ABC::Header;
use ABC::Tune;
use ABC::Grammar;
use ABC::Actions;

class Context {
    
}

sub HeaderToLilypond(ABC::Header $header) {
    say "\\header \{";
    
    my @titles = $header.get("T")>>.value;
    say "    title = \"{ @titles[0] }\"";
    
    say "}";
}

my %note-map = ( 'C' => "c'",
                 'D' => "d'",
                 'E' => "e'",
                 'F' => "f'",
                 'G' => "g'",
                 'A' => "a'",
                 'B' => "b'",
                 'c' => "c''",
                 'd' => "d''",
                 'e' => "e''",
                 'f' => "f''",
                 'g' => "g''",
                 'a' => "a''",
                 'b' => "b''"
   );
   
my %cheat-length-map = ( '/' => "16",
                         "" => "8",
                         "1" => "8",
                         "2" => "4",
                         "3" => "4."
    );
   
sub StemToLilypond(Context $context, $stem) {
    my $match = ABC::Grammar.parse($stem, :rule<mnote>); # bad in at least two ways....
    my $pitch = ~$match<pitch>;
    my $length = ~$match<note_length>;
    
    print " { %note-map{$pitch} }{ %cheat-length-map{$length} } ";
}
   
sub BodyToLilypond(Context $context, @elements) {
    say "\{";
    
    for @elements -> $element {
        given $element.key {
            when "stem" { StemToLilypond($context, $element.value); }
            when "barline" { say " |"; }
        }
    }
    
    say "\}";
}

my $match = ABC::Grammar.parse($*IN.slurp, :rule<tune_file>, :actions(ABC::Actions.new));

# just work with the first tune for now
my $tune = @( $match.ast )[0][0];

say '\\version "2.12.3"';
HeaderToLilypond($tune.header);
BodyToLilypond(Context.new, $tune.music);
