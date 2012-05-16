use v6;
use ABC::Header;
use ABC::Tune;
use ABC::Grammar;
use ABC::Actions;
use ABC::Duration; #OK
use ABC::Note;
use ABC::LongRest;

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
            when "1/16" { %cheat-length-map = ( '/' => "32",
                                               "" => "16",
                                               "1" => "16",
                                               "3/2" => "16.",
                                               "2" => "8",
                                               "3" => "8.",
                                               "7/2" => "8..",
                                               "4" => "4",
                                               "6" => "4.",
                                               "8" => "2");
            }
            when "1/8" { %cheat-length-map = ( "1/4" => "32",
                                               '/' => "16",
                                               "3/4" => "16.",
                                               "" => "8",
                                               "1" => "8",
                                               "3/2" => "8.",
                                               "2" => "4",
                                               "3" => "4.",
                                               "7/2" => "4..",
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
            ($.key{$match<basenote>.uc} // "") ~ $match<basenote> ~ ($match<octave> // "");
        }
    }
    
    method get-Lilypond-pitch($abc-pitch) {
        # say :$abc-pitch.perl;
        my $real-pitch = self.get-real-pitch($abc-pitch);
        # say :$real-pitch.perl;
        my $match = ABC::Grammar.parse($real-pitch, :rule<pitch>);
        
        my $octave = +((~$match<basenote>) ~~ 'a'..'z');
        given $match<octave> {
            when !*.defined { } # skip if no additional octave info
            when /\,/ { $octave -= (~$match<octave>).chars }
            when /\'/ { $octave += (~$match<octave>).chars }
        }
        
        $match<basenote>.lc ~ %accidental-map{~($match<accidental> // "")} ~ %octave-map{$octave};
    }

    method get-Lilypond-duration(ABC::Duration $abc-duration) {
        die "Unknown duration { $abc-duration.duration-to-str }" unless %.cheat-length-map{$abc-duration.duration-to-str};
        %.cheat-length-map{$abc-duration.duration-to-str};
    }
    
    method meter-to-string() {
        given $.meter {
            when "C"  { "\\time 4/4" }
            when "C|" { "\\time 2/2" }
            "\\time $.meter ";
        }
    }

    method ticks-in-measure() {
        given $.meter {
            when "C" | "C|" { 1 / $.length.eval; }
            $.meter.eval / $.length.eval;
        }
    }

    method get-Lilypond-measure-length() {
        given $.meter {
            when "C" | "C|" | "4/4" { "1" }
            when "3/4" | 6/8 { "2." }
            when "2/4" { "2" }
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

sub HeaderToLilypond(ABC::Header $header, $out) {
    $out.say: "\\header \{";
    
    my $title = $header.get-first-value("T");
    $title .=subst('"', "'", :g);
    $out.say: "    piece = \" $title \"";
    my @composers = $header.get("C")>>.value;
    $out.say: "    composer = \"{ @composers[0] }\"" if ?@composers;
    
    $out.say: "}";
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
    
    method StemPitchToLilypond($stem) {
        given $stem {
            when ABC::Note {
                $.context.get-Lilypond-pitch($stem.pitch)
            }

            when ABC::Stem {
                "<" ~ $stem.notes.map({ $.context.get-Lilypond-pitch($_.pitch) }).join(' ') ~ ">"
            }

            die "Unrecognized alleged stem: " ~ $stem.perl;
        }
    }
    
    method StemToLilypond($stem, $suffix = "") {
        " " ~ self.StemPitchToLilypond($stem)
            ~ $.context.get-Lilypond-duration($stem)
            ~ ($stem.is-tie ?? '~' !! '')
            ~ $suffix
            ~ " ";
    }
    
    method WrapBar($lilypond-bar, $duration) {
        my $ticks-in-measure = $.context.ticks-in-measure;
        my $result = "";
        if $duration % $ticks-in-measure != 0 {
            my $note-length = 1 / $.context.length.eval;
            my $count = $duration % $ticks-in-measure;
            if $count ~~ Rat {
                while $count.denominator > 1 {
                    $note-length *= 2; # makes twice as short
                    $count *= 2;       # makes twice as long
                }
            }
            $result = "\\partial { $note-length }*{ $count } ";
        }
        
        $result ~ $lilypond-bar; 
    }
    
    method SectionToLilypond(@elements, $out) {
        my $notes = "";
        my $lilypond = "";
        my $duration = 0;
        my $chord-duration = 0;
        my $suffix = "";
        my $in-slur = False;
        for @elements -> $element {
            $duration += self.Duration($element);
            $chord-duration += self.Duration($element);
            given $element.key {
                when "stem" { 
                    $lilypond ~= self.StemToLilypond($element.value, $suffix); 
                    $suffix = ""; 
                }
                when "rest" { 
                    $lilypond ~=  " r{ $.context.get-Lilypond-duration($element.value) }$suffix "; 
                    $suffix = ""; 
                }
                when "tuplet" { 
                    $lilypond ~= " \\times 2/{ $element.value.tuple } \{";
                    $lilypond ~= self.StemToLilypond($element.value.notes[0], "[");
                    for 1..($element.value.notes - 2) -> $i {
                        $lilypond ~= self.StemToLilypond($element.value.notes[$i]);
                    }
                    $lilypond ~= self.StemToLilypond($element.value.notes[*-1], "]");
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
                        when "fermata" { $suffix ~= "\\fermata"; }
                        when "trill" { $suffix ~= "\\trill"; }
                        when /^p+$/ | "mp" | "mf" | /^f+$/ 
                                 { $suffix ~= "\\" ~ $element.value; }
                        $*ERR.say: "Unrecognized gracing: " ~ $element.value.perl;
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
                    $in-slur = True;
                }
                when "slur_end" {
                    $lilypond .= subst(/(\s+)$/, { ")$_" }) if $in-slur;
                    $*ERR.say: "Warning: End-slur found without begin-slur" unless $in-slur;
                    $in-slur = False;
                }
                when "multi_measure_rest" {
                    $lilypond ~= "\\compressFullBarRests R"
                               ~ $!context.get-Lilypond-measure-length
                               ~ "*"
                               ~ $element.value.measures_rest ~ " ";
                }
                when "chord_or_text" {
                    for @($element.value) -> $chord_or_text {
                        if $chord_or_text ~~ ABC::Chord {
                            $suffix ~= '^"' ~ $chord_or_text ~ '"';
                        } else {
                            given $element.value {
                                when /^ '^'(.*)/ { $suffix ~= '^"' ~ $0 ~ '" ' }
                            }
                        }
                    }
                }
                when "grace_notes" {
                    $*ERR.say: "Unused suffix in grace note code: $suffix" if $suffix;
                    
                    $lilypond ~= "\\grace \{";
                    if $element.value.notes == 1 {
                        $lilypond ~= self.StemToLilypond($element.value.notes[0], ""); 
                    } else {
                        $lilypond ~= self.StemToLilypond($element.value.notes[0], "[");
                        for 1..^($element.value.notes - 1) {
                            $lilypond ~= self.StemToLilypond($element.value.notes[$_], "");
                        }
                        $lilypond ~= self.StemToLilypond($element.value.notes[*-1], "]");
                    }
                    $lilypond ~= " \} ";
                    
                    $suffix = "";
                }
                # .say;
            }
        }
    
        $out.say: "\{";
        $notes ~= self.WrapBar($lilypond, $duration);
        $out.say: $notes;
        $out.say: " \}";
    }
    
    method BodyToLilypond(@elements, $out) {
        $out.say: "\{";
        $out.print: $.context.key-to-string;
        $out.print: $.context.meter-to-string;
    
        my $start-of-section = 0;
        loop (my $i = 0; $i < +@elements; $i++) {
            # say @elements[$i].WHAT;
            if @elements[$i].key eq "nth_repeat"
               || ($i > $start-of-section 
                   && @elements[$i].key eq "barline" 
                   && @elements[$i].value ne "|") {
                if @elements[$i].key eq "nth_repeat" 
                   || @elements[$i].value eq ':|:' | ':|' | '::' {
                    $out.print: "\\repeat volta 2 "; # 2 is abitrarily chosen here!
                }
                self.SectionToLilypond(@elements[$start-of-section ..^ $i], $out);
                $start-of-section = $i + 1;
                # if @elements[$i].value eq '||' {
                #     say '\\bar "||"';
                # }
                if @elements[$i].value eq '|]' {
                    $out.say: '\\bar "|."';
                }
            }

            if @elements[$i].key eq "nth_repeat" {
                my $final-bar = False;
                $out.say: "\\alternative \{";
                my $endings = 0;
                loop (; $i < +@elements; $i++) {
                    # say @elements[$i].WHAT;
                    if @elements[$i].key eq "barline" 
                       && @elements[$i].value ne "|" {
                           self.SectionToLilypond(@elements[$start-of-section ..^ $i], $out);
                           $start-of-section = $i + 1;
                           $final-bar = True if @elements[$i].value eq '|]';
                           last if ++$endings == 2;
                    }
                }
                if $endings == 1 {
                    self.SectionToLilypond(@elements[$start-of-section ..^ $i], $out);
                    $start-of-section = $i + 1;
                    $final-bar = True if $i < +@elements && @elements[$i].value eq '|]';
                }
                $out.say: "\}";
                
                if $final-bar {
                    $out.say: '\\bar "|."';
                }
                
            }
        }
    
        if $start-of-section + 1 < @elements.elems {
            if @elements[*-1].value eq ':|:' | ':|' | '::' {
                $out.print: "\\repeat volta 2 "; # 2 is abitrarily chosen here!
            }
            self.SectionToLilypond(@elements[$start-of-section ..^ +@elements], $out);
            if @elements[*-1].value eq '|]' {
                $out.say: '\\bar "|."';
            }
        }
    
        $out.say: "\}";
    }
    
}

sub TuneStreamToLilypondStream($in, $out) {
    my $match = ABC::Grammar.parse($in.slurp, :rule<tune_file>, :actions(ABC::Actions.new));

    $out.say: '\\version "2.12.3"';
    $out.say: "#(set-default-paper-size \"{$paper-size}\")";
    
    for @( $match.ast ) -> $tune {
        $*ERR.say: "Working on { $tune.header.get-first-value("T") // $tune.header.get-first-value("X") }";
        $out.say: "\\score \{";

        # say ~$tune.music;

        my $key = $tune.header.get-first-value("K");
        my $meter = $tune.header.get-first-value("M");
        my $length = $tune.header.get-first-value("L") // "1/8";

        my $convertor = TuneConvertor.new($key, $meter, $length);
        $convertor.BodyToLilypond($tune.music, $out);
        HeaderToLilypond($tune.header, $out);

        $out.say: "}\n\n";    
    }
}

multi sub MAIN() {
    TuneStreamToLilypondStream($*IN, $*OUT);
}

multi sub MAIN($abc-file) {
    my $ly-file = $abc-file ~ ".ly";
    if $abc-file ~~ /^(.*) ".abc"/ {
        $ly-file = $0 ~ ".ly";
    }
    $*ERR.say: "Reading $abc-file, writing $ly-file";
    
    my $in = open $abc-file, :r or die "Unable to open $abc-file";
    my $out = open $ly-file, :w or die "Unable to open $ly-file";
    
    TuneStreamToLilypondStream($in, $out);
    
    $out.close;
    $in.close;
}
