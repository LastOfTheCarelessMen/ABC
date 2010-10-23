use v6;
use ABC::Header;
use ABC::Tune;
use ABC::Grammar;
use ABC::Actions;
use ABC::Duration;
use ABC::Note;

my %accidental-map = ( ''  => "",
                       '='  => "",
                       '^'  => "is",
                       '^^' => "isis",
                       '_'  => "es",
                       '__' => "eses" );

my %octave-map = ( 0  => "'",
                   1  => "''" );

class Context {
    has %.key;
    
    method new(%key) {
        self.bless(*, :%key)
    }
    
    method get-real-pitch($nominal-pitch) {
        my $match = ABC::Grammar.parse($nominal-pitch, :rule<pitch>);
        if $match<accidental> {
            $nominal-pitch;
        } else {
            ($.key{$match<basenote>.uc} // "") ~ $match<basenote> ~ $match<octave>;
        }
    }
    
    method get-Lilypond-pitch($abc-pitch) {
        # say :$abc-pitch.perl;
        my $real-pitch = self.get-real-pitch($abc-pitch);
        # say :$real-pitch.perl;
        my $match = ABC::Grammar.parse($real-pitch, :rule<pitch>);
        
        my $octave = +((~$match<basenote>) ~~ 'a'..'z');
        # SHOULD: factor in $match<octave> too
        
        $match<basenote>.lc ~ %accidental-map{~$match<accidental>} ~ %octave-map{$octave};
    }
}

sub HeaderToLilypond(ABC::Header $header) {
    say "\\header \{";
    
    my @titles = $header.get("T")>>.value;
    say "    title = \"{ @titles[0] }\"";
    
    say "}";
}

sub Duration(Context $context, $element) {
    $element.value ~~ ABC::Duration ?? $element.value.ticks !! 0;
}

my %cheat-length-map = ( '/' => "16",
                         "" => "8",
                         "1" => "8",
                         "2" => "4",
                         "3" => "4."
    );
    
sub DurationToLilypond(Context $context, ABC::Duration $duration) {
    %cheat-length-map{$duration.duration-to-str};
}
   
sub StemToLilypond(Context $context, $stem) {
    if $stem ~~ ABC::Note {
        print " { $context.get-Lilypond-pitch($stem.pitch) }{ DurationToLilypond($context, $stem) } ";
    }
}
   
sub SectionToLilypond(Context $context, @elements) {
    say "\{";
    
    for @elements -> $element {
        given $element.key {
            when "stem" { StemToLilypond($context, $element.value); }
            when "rest" { print " r{ DurationToLilypond($context, $element.value) } " }
            when "barline" { say " |"; }
            when "tuplet" { 
                print " \\times 2/3 \{"; 
                for $element.value.notes -> $stem {
                    # say :$stem.perl;
                    # say $stem.WHAT;
                    StemToLilypond($context, $stem);
                }
                print " } ";  
            }
        }
    }
    
    say "\}";
}

sub BodyToLilypond(Context $context, $key, @elements) {
    say "\{";
    say "\\key $key \\major";

    my $start-of-section = 0;
    my $duration-in-section = 0;
    for @elements.keys -> $i {
        if $i > $start-of-section 
           && @elements[$i].key eq "barline" 
           && @elements[$i].value ne "|" {
            if $duration-in-section % 8 != 0 {
                print "\\partial 8*{ $duration-in-section % 8 } ";
            }
            
            if @elements[$i].value eq ':|:' | ':|' | '::' {
                print "\\repeat volta 2 "; # 2 is abitrarily chosen here!
            }
            SectionToLilypond($context, @elements[$start-of-section ..^ $i]);
            $start-of-section = $i + 1;
            $duration-in-section = 0;
        }
        $duration-in-section += Duration($context, @elements[$i]);
    }
    
    if $start-of-section + 1 < @elements.elems {
        if $duration-in-section % 8 != 0 {
            print "\\partial 8*{ $duration-in-section % 8 } ";
        }
        
        if @elements[*-1].value eq ':|:' | ':|' | '::' {
            print "\\repeat volta 2 "; # 2 is abitrarily chosen here!
        }
        SectionToLilypond($context, @elements[$start-of-section ..^ +@elements]);
    }

    say "\}";
}


my $match = ABC::Grammar.parse($*IN.slurp, :rule<tune_file>, :actions(ABC::Actions.new));

# just work with the first tune for now
my $tune = @( $match.ast )[0][0];

say '\\version "2.12.3"';
HeaderToLilypond($tune.header);
my $key = $tune.header.get("K")[0].value;

BodyToLilypond(Context.new(key_signature($key)),
               $key.comb(/./)[0].lc,
               $tune.music);
