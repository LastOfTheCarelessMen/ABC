use v6;
use ABC::Header;
use ABC::Tune;
use ABC::Grammar;
use ABC::Actions;
use ABC::Duration;
use ABC::Note;

my $paper-size = "letter"; # or switch to "a4" for European paper

my %accidental-map = ( ''  => "",
                       '='  => "",
                       '^'  => "is",
                       '^^' => "isis",
                       '_'  => "es",
                       '__' => "eses" );

my %octave-map = ( -1 => "",
                    0 => "'",
                    1 => "''",
                    2 => "'''" );

class Context {
    has $.key-name;
    has %.key;
    has $.meter;
    has $.length;
    has %.cheat-length-map;
    
    method new($key-name, $meter, $length) {
        my %cheat-length-map;
        given $length {
            when "1/8" { %cheat-length-map = ( '/' => "16",
                                               "" => "8",
                                               "1" => "8",
                                               "3/2" => "8.",
                                               "2" => "4",
                                               "3" => "4.",
                                               "4" => "2",
                                               "6" => "2.",
                                               "8" => "1");
            }
            when "1/4" { %cheat-length-map = ( '/' => "8",
                                               "" => "4",
                                               "1" => "4",
                                               "3/2" => "4.",
                                               "2" => "2",
                                               "3" => "2.",
                                               "4" => "1",
                                               "6" => "1.");
            }
            die "Don't know how to handle note length $length";
        }
        self.bless(*, :$key-name, 
                      :key(key_signature($key-name)), 
                      :$meter, 
                      :$length, 
                      :%cheat-length-map);
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
        given $match<octave> {
            when /\,/ { $octave -= (~$match<octave>).chars }
            when /\'/ { $octave += (~$match<octave>).chars }
        }
        
        $match<basenote>.lc ~ %accidental-map{~$match<accidental>} ~ %octave-map{$octave};
    }

    method get-Lilypond-duration(ABC::Duration $abc-duration) {
        %.cheat-length-map{$abc-duration.duration-to-str};
    }
    
    method meter-to-string() {
        "\\time $.meter ";
    }

    method ticks-in-measure() {
        given $.meter {
            when "C" { 1 / $.length.eval; }
            $.meter.eval / $.length.eval;
        }
    }
    
    method key-to-string() {
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
        "\\key $major-key-name \\major\n";
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

    method new($key, $meter, $length) {
        self.bless(*, :context(Context.new($key, $meter, $length)));
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
                ~ ($stem.is-tie ?? '~' !! '')
                ~ $suffix
                ~ " ";
            }
            "";
        }
    }
    
    method WrapBar($lilypond-bar, $duration) {
        my $ticks-in-measure = $.context.ticks-in-measure;
        my $result = "";
        if $duration % $ticks-in-measure != 0 {
            $result = "\\partial { 1 / $.context.length.eval }*{ $duration % $ticks-in-measure } ";
        }
        
        $result ~ $lilypond-bar; 
    }
    
    method SectionToLilypond(@elements) {
        my $chords = "";
        my $notes = "";
        my $lilypond = "";
        my $duration = 0;
        my $chord-duration = 0;
        my $suffix = "";
        for @elements -> $element {
            $duration += self.Duration($element);
            $chord-duration += self.Duration($element);
            given $element.key {
                when "stem" { 
                    $lilypond ~= self.StemToLilypond($element.value, $suffix); 
                    $suffix = ""; 
                }
                when "rest" { 
                    $lilypond ~=  " r{ $.context.get-Lilypond-duration($element.value) } "; 
                    $suffix = ""; 
                }
                when "tuplet" { 
                    $lilypond ~= " \\times 2/3 \{";
                    if +$element.value.notes == 3 && $element.value.ticks == 2 {
                        $lilypond ~= self.StemToLilypond($element.value.notes[0], "[");
                        $lilypond ~= self.StemToLilypond($element.value.notes[1]);
                        $lilypond ~= self.StemToLilypond($element.value.notes[2], "]");
                    } else {
                        for $element.value.notes -> $stem {
                            $lilypond ~= self.StemToLilypond($stem);
                        }
                    }
                    $lilypond ~= " } ";  
                    $suffix = "";
                }
                when "broken_rhythm" {
                    $lilypond ~= self.StemToLilypond($element.value.effective-stem1, $suffix);
                    # MUST: handle interior graciings
                    $lilypond ~= self.StemToLilypond($element.value.effective-stem2);
                    $suffix = "";
                }
                when "gracing" {
                    given $element.value {
                        when "~" { $suffix ~= "\\turn"; }
                        when "." { $suffix ~= "\\staccato"; }
                        when /^p+$/ | "mp" | "mf" | /^f+$/ 
                                 { $suffix ~= "\\" ~ $element.value; }
                    }
                }
                when "barline" {
                    $notes ~= self.WrapBar($lilypond, $duration);
                    $notes ~= " |\n"; 
                    $lilypond = "";
                    $duration = 0;
                }
                when "inline_field" {
                    given $element.value.key {
                        when "K" { 
                            $!context = Context.new($element.value.value, 
                                                    $!context.meter, 
                                                    $!context.length); 
                            $lilypond ~= $!context.key-to-string;
                        }
                        when "M" {
                            $!context = Context.new($!context.key-name,
                                                    $element.value.value,
                                                    $!context.length);
                            $lilypond ~= $!context.meter-to-string;
                        }
                        when "L" {
                            $!context = Context.new($!context.key-name,
                                                    $!context.meter,
                                                    $element.value.value);
                        }
                    }
                }
                when "slur_begin" {
                    $suffix ~= "(";
                }
                when "slur_end" {
                    $lilypond .= subst(/(\s+)$/, { ")$0" });
                }
                # .say;
            }
        }
    
        say "\{";
        $notes ~= self.WrapBar($lilypond, $duration);
        say $notes;
        say " \}";
    }
    
    method BodyToLilypond(@elements) {
        say "\{";
        print $.context.key-to-string;
        printf $.context.meter-to-string;
    
        my $start-of-section = 0;
        loop (my $i = 0; $i < +@elements; $i++) {
            # say @elements[$i].WHAT;
            if @elements[$i].key eq "nth_repeat"
               || ($i > $start-of-section 
                   && @elements[$i].key eq "barline" 
                   && @elements[$i].value ne "|") {
                if @elements[$i].key eq "nth_repeat" 
                   || @elements[$i].value eq ':|:' | ':|' | '::' {
                    print "\\repeat volta 2 "; # 2 is abitrarily chosen here!
                }
                self.SectionToLilypond(@elements[$start-of-section ..^ $i]);
                $start-of-section = $i + 1;
                # if @elements[$i].value eq '||' {
                #     say '\\bar "||"';
                # }
                if @elements[$i].value eq '|]' {
                    say '\\bar "|."';
                }
            }

            if @elements[$i].key eq "nth_repeat" {
                my $final-bar = False;
                say "\\alternative \{";
                my $endings = 0;
                loop (; $i < +@elements; $i++) {
                    # say @elements[$i].WHAT;
                    if @elements[$i].key eq "barline" 
                       && @elements[$i].value ne "|" {
                           self.SectionToLilypond(@elements[$start-of-section ..^ $i]);
                           $start-of-section = $i + 1;
                           $final-bar = True if @elements[$i].value eq '|]';
                           last if ++$endings == 2;
                    }
                }
                if $endings == 1 {
                    # say @elements[$i].WHAT;
                    self.SectionToLilypond(@elements[$start-of-section ..^ $i]);
                    $start-of-section = $i + 1;
                    $final-bar = True if @elements[$i].value eq '|]';
                }
                say "\}";
                
                if $final-bar {
                    say '\\bar "|."';
                }
                
            }
        }
    
        if $start-of-section + 1 < @elements.elems {
            if @elements[*-1].value eq ':|:' | ':|' | '::' {
                print "\\repeat volta 2 "; # 2 is abitrarily chosen here!
            }
            self.SectionToLilypond(@elements[$start-of-section ..^ +@elements]);
            if @elements[*-1].value eq '|]' {
                say '\\bar "|."';
            }
        }
    
        say "\}";
    }
    
}

my $match = ABC::Grammar.parse($*IN.slurp, :rule<tune_file>, :actions(ABC::Actions.new));

say '\\version "2.12.3"';
say "#(set-default-paper-size \"{$paper-size}\")";

for @( $match.ast ) -> $tune {
    say "\\score \{";
    
    # say ~$tune.music;

    my $key = $tune.header.get("K")[0].value;
    my $meter = $tune.header.get("M")[0].value;
    my $length = $tune.header.get("L") ?? $tune.header.get("L")[0].value !! "1/8";

    my $convertor = TuneConvertor.new($key, $meter, $length);
    $convertor.BodyToLilypond($tune.music);
    HeaderToLilypond($tune.header);

    say "}\n\n";    
}

