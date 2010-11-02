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
    has $.key-name;
    has %.key;
    has $.meter;
    
    method new($key-name, $meter) {
        self.bless(*, :$key-name, :key(key_signature($key-name)), :$meter);
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

    my %cheat-length-map = ( '/' => "16",
                             "" => "8",
                             "1" => "8",
                             "3/2" => "8.",
                             "2" => "4",
                             "3" => "4."
        );
    
    method get-Lilypond-duration(ABC::Duration $abc-duration) {
        %cheat-length-map{$abc-duration.duration-to-str};
    }
    
    method write-meter() {
        print "\\time $.meter ";
    }

    method eighths-in-measure() {
        given $.meter {
            when "6/8" { 6; }
            when "9/8" { 9; }
            8;
        }
    }
    
    method write-key() {
        my $sf = %.key.map({ "{.key}{.value}" }).sort.Str.lc;
        my $major-key-name;
        given $sf {
            when ""                     { $major-key-name = "c"; }
            when "f^"                   { $major-key-name = "g"; }
            when "c^ f^"                { $major-key-name = "d"; }
            when "c^ f^ g^"             { $major-key-name = "a"; }
            when "c^ d^ f^ g^"          { $major-key-name = "e"; }
            when "a^ c^ d^ f^ g^"       { $major-key-name = "b"; }
            when "a^ c^ d^ e^ f^ g^"    { $major-key-name = "fis"; }
            when "a^ b^ c^ d^ e^ f^ g^" { $major-key-name = "cis"; }
            when "b_"                   { $major-key-name = "f"; }
            when "b_ e_"                { $major-key-name = "bes"; }
            when "a_ b_ e_"             { $major-key-name = "ees"; }
            when "a_ b_ d_ e_"          { $major-key-name = "aes"; }
            when "a_ b_ d_ e_ g_"       { $major-key-name = "des"; }
            when "a_ b_ c_ d_ e_ g_"    { $major-key-name = "ges"; }
            when "a_ b_ c_ d_ e_ f_ g_" { $major-key-name = "ces"; }
        }
        say "\\key $major-key-name \\major";
    }
}

sub HeaderToLilypond(ABC::Header $header) {
    say "\\header \{";
    
    my @titles = $header.get("T")>>.value;
    say "    piece = \"{ @titles[0] }\"";
    my @composers = $header.get("C")>>.value;
    say "    composer = \"{ @composers[0] }\"" if ?@composers;
    
    say "}";
}

class TuneConvertor {
    has $.context;

    method new($key, $meter) {
        self.bless(*, :context(Context.new($key, $meter)));
    }

    # MUST: this is context dependent too
    method Duration($element) {
        $element.value ~~ ABC::Duration ?? $element.value.ticks !! 0;
    }
    
    method StemToLilypond($stem, $suffix = "") {
        given $stem {
            when ABC::Note {
                " "
                ~ $.context.get-Lilypond-pitch($stem.pitch)
                ~ $.context.get-Lilypond-duration($stem)
                ~ $suffix
                ~ " ";
            }
            "";
        }
    }
    
    method WriteBar($lilypond-bar, $duration) {
        my $eighths = $.context.eighths-in-measure;
        if $duration % $eighths != 0 {
            print "\\partial 8*{ $duration % $eighths } ";
        }
        
        print "$lilypond-bar"; 
    }
    
    method SectionToLilypond(@elements) {
        say "\{";
    
        my $lilypond = "";
        my $duration = 0;
        my $suffix = "";
        for @elements -> $element {
            $duration += self.Duration($element);
            given $element.key {
                when "stem" { $lilypond ~= self.StemToLilypond($element.value, $suffix); }
                when "rest" { $lilypond ~=  " r{ $.context.get-Lilypond-duration($element.value) } " }
                when "tuplet" { 
                    $lilypond ~= " \\times 2/3 \{"; 
                    for $element.value.notes -> $stem {
                        $lilypond ~= self.StemToLilypond($stem);
                    }
                    $lilypond ~= " } ";  
                }
                when "broken_rhythm" {
                    $lilypond ~= self.StemToLilypond($element.value.effective-stem1, $suffix);
                    # MUST: handle interior graciings
                    $lilypond ~= self.StemToLilypond($element.value.effective-stem2);
                }
                when "gracing" {
                    given $element.value {
                        when "~" { $suffix ~= "\\turn"; next; }
                        when "." { $suffix ~= "\\staccato"; next; }
                    }
                }
                when "barline" {
                    self.WriteBar($lilypond, $duration);
                    say " |"; 
                    $lilypond = "";
                    $duration = 0;
                }
                when "inline_field" {
                    given $element.value.key {
                        when "K" { 
                            $!context = Context.new($element.value.value, $!context.meter); 
                            $!context.write-key;
                        }
                        when "M" {
                            $!context = Context.new($!context.key-name, $element.value.value);
                            $!context.write-meter;
                        }
                    }
                }
                # .say;
            }
    
            $suffix = "";
        }
    
        self.WriteBar($lilypond, $duration);
        say " \}";
    }
    
    method BodyToLilypond(@elements) {
        say "\{";
        $.context.write-key;
        $.context.write-meter;
    
        my $start-of-section = 0;
        for @elements.keys -> $i {
            if $i > $start-of-section 
               && @elements[$i].key eq "barline" 
               && @elements[$i].value ne "|" {
                if @elements[$i].value eq ':|:' | ':|' | '::' {
                    print "\\repeat volta 2 "; # 2 is abitrarily chosen here!
                }
                self.SectionToLilypond(@elements[$start-of-section ..^ $i]);
                $start-of-section = $i + 1;
            }
        }
    
        if $start-of-section + 1 < @elements.elems {
            if @elements[*-1].value eq ':|:' | ':|' | '::' {
                print "\\repeat volta 2 "; # 2 is abitrarily chosen here!
            }
            self.SectionToLilypond(@elements[$start-of-section ..^ +@elements]);
        }
    
        say "\}";
    }
    
}

my $match = ABC::Grammar.parse($*IN.slurp, :rule<tune_file>, :actions(ABC::Actions.new));

say '\\version "2.12.3"';

for @( $match.ast ) -> $tune {
    say "\\score \{";

    my $key = $tune.header.get("K")[0].value;
    my $meter = $tune.header.get("M")[0].value;

    my $convertor = TuneConvertor.new($key, $meter);
    $convertor.BodyToLilypond($tune.music);
    HeaderToLilypond($tune.header);

    say "}";    
}

