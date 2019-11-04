use v6;
use ABC::Header;
use ABC::Tune;
use ABC::Grammar;
use ABC::Actions;
use ABC::Duration; #OK
use ABC::Note;
use ABC::LongRest;
use ABC::Utils;
use ABC::KeyInfo;
use ABC::Context;

my $use-ABC-line-breaks = True; # false will use Lilypond's judgment

my %accidental-map = ( ''  => "",
                       '='  => "",
                       '^'  => "is",
                       '^^' => "isis",
                       '_'  => "es",
                       '__' => "eses" );

my %octave-map = ( -3 => ",,",
                   -2 => ",",
                   -1 => "",
                    0 => "'",
                    1 => "''",
                    2 => "'''" );

my %unrecognized_gracings;
my %substitutes;

my $spacing-comment = '%{ spacing %}';
                
sub sanitize-quotation-marks($string) is export {
    my $s = $string;
    $s.=subst(/^^ '"' (\S)/, {"“$0"}, :global);
    $s.=subst(/<?after \s> '"' (\S)/, {"“$0"}, :global);
    $s.=subst(/'"'/, "”", :global);
    $s.=subst(/<!wb>"'"(\S)/, {"‘$0"}, :global);
    $s.=subst(/"'"/, "’", :global);
    
    my @subs = %substitutes.keys;
    $s.=subst(/ (@subs) /, { %substitutes{$0} }, :global);
    
    $s;
}

class LilypondContext {
    has ABC::Context $.context;
    
    method new($key-name, $meter, $length, :$current-key-info) {
        self.bless(context => ABC::Context.new($key-name, $meter, $length, :$current-key-info));
    }

    method bar-line { $.context.bar-line; }

    method get-Lilypond-pitch(ABC::Note $abc-pitch) {
        my $real-accidental = $.context.working-accidental($abc-pitch);
        
        my $octave = +($abc-pitch.basenote ~~ 'a'..'z') + $.context.key-info.octave-shift;
        given $abc-pitch.octave {
            when !*.defined { } # skip if no additional octave info
            when /\,/ { $octave -= $abc-pitch.octave.chars }
            when /\'/ { $octave += $abc-pitch.octave.chars }
        }
        
        $abc-pitch.basenote.lc ~ %accidental-map{$real-accidental} ~ %octave-map{$octave};
    }

    method get-Lilypond-duration(ABC::Duration $abc-duration) {
        my $ticks = $abc-duration.ticks.Rat * $.context.length;
        my $dots = "";
        given $ticks.numerator {
            when 3 { $dots = ".";  $ticks *= 2/3; }
            when 7 { $dots = ".."; $ticks *= 4/7; }
        }
        die "Don't know how to handle duration { $abc-duration.ticks }" unless is-a-power-of-two($ticks);
        die "Don't know how to handle duration { $abc-duration.ticks }" if $ticks > 4;
        if $ticks == 4 { 
            "\\longa" ~ $dots;
        } elsif $ticks == 2 { 
            "\\breve" ~ $dots;
        } else {
            $ticks.denominator ~ $dots;
        }
    }
    
    method meter-to-string() {
        given $.context.meter {
            when "none" { "" }
            when "C" { "\\time 4/4" }
            when "C|" { "\\time 2/2" }
            when "6/4" { "\\time 6/4 \\set Timing.beatStructure = 2,2,2"}
            "\\time { $.context.meter } ";
        }
    }

    method ticks-in-measure() {
        given $.context.meter {
            when "C" | "C|" { 1 / $.context.length; }
            when "none" { Inf }
            $.context.meter / $.context.length;
        }
    }

    method get-Lilypond-measure-length() {
        given $.context.meter.trim {
            when "C" | "C|" | "4/4" { "1" }
            when "3/4" | 6/8 { "2." }
            when "2/4" { "2" }
        }
    }
    
    method key-to-string() {
        my $sf = $.context.key-info.key.flatmap({ "{.key}{.value}" }).sort.Str.lc;
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
    
    method clef-to-string() {
        my $lilypond-clef = "treble";
        given $.context.key-info.clef {
            when not .defined { }
            when "treble" | "alto" | "tenor" | "bass" { $lilypond-clef = ~$.context.key-info.clef; }
        }
        "\\clef $lilypond-clef";
    }
}

sub get-field-if-there($header, $field) {
    my @things = $header.get($field)>>.value;
    ?@things ?? @things[0] !! "";
}

class TuneConvertor {
    has $.context;

    method new($key, $meter, $length) {
        self.bless(:context(LilypondContext.new($key, $meter, $length)));
    }

    # MUST: this is context dependent too
    method Duration($element) {
        $element.value ~~ ABC::Duration ?? $element.value.ticks !! 0;
    }
    
    method StemPitchToLilypond($stem) {
        given $stem {
            when ABC::Note {
                $.context.get-Lilypond-pitch($stem)
            }

            when ABC::Stem {
                "<" ~ $stem.notes.map({
                    $.context.get-Lilypond-pitch($_) ~ ($_.is-tie ?? '~' !! '')
                }).join(' ') ~ ">"
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
    
    method WrapBar($lilypond-bar, $duration, :$beginning?) {
        my $ticks-in-measure = $.context.ticks-in-measure;
        my $result = "";

        if $ticks-in-measure == Inf {
            $result ~= "\\cadenzaOn ";
            
            my @chunks = $lilypond-bar.split($spacing-comment);
            for @chunks -> $chunk {
                if $chunk !~~ /"["/ && $chunk.comb(/\d+/).grep(* > 4) > 1 {
                    $result ~= $chunk.subst(/<?after \S> \s/, { "[ " }) ~ "]";
                } else {
                    $result ~= $chunk;
                }
            }
            
            $result ~= " \\cadenzaOff";
        } else {
            if $beginning && $duration % $ticks-in-measure != 0 {
                my $note-length = 1 / $.context.context.length;
                my $count = $duration % $ticks-in-measure;
                if $count ~~ Rat {
                    die "Strange partial measure found: $lilypond-bar" unless is-a-power-of-two($count.denominator);

                    while $count.denominator > 1 {
                        $note-length *= 2; # makes twice as short
                        $count *= 2;       # makes twice as long
                    }
                }
                $result = "\\partial { $note-length }*{ $count } ";
            }
            $result ~= $lilypond-bar;
        }

        $result; 
    }
    
    method SectionToLilypond(@elements, $out, :$beginning?) {
        my $first-time = $beginning // False;
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
                    given $element.value.tuple {
                        when 2 { $lilypond ~= " \\times 3/2 \{"; }
                        when 3 { $lilypond ~= " \\times 2/3 \{"; }
                        when 4 { $lilypond ~= " \\times 3/4 \{"; }
                        $lilypond ~= " \\times 2/{ $element.value.tuple } \{";
                    }
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
                        when "T" { $suffix ~= "\\trill"; }
                        when "P" { $suffix ~= "\\prall"; }
                        when "segno"  { $lilypond ~= '\\mark \\markup { \\musicglyph #"scripts.segno" }'; }
                        when "coda"   { $lilypond ~= '\\mark \\markup { \\musicglyph #"scripts.coda" }'; }
                        when "D.C."   { $lilypond ~= '\\mark "D.C."'; }
                        when "D.S."   { $lilypond ~= '\\mark "D.S."'; }
                        when "fine"   { $suffix ~= '^\\markup { \\center-align { Fine } } '; }
                        when "breath" { $lilypond ~= '\\breathe'; }
                        when "crescendo(" | "<("  { $suffix ~= "\\<"; }
                        when "crescendo)" | "<)"  { $suffix ~= "\\!"; }
                        when "diminuendo(" | ">(" { $suffix ~= "\\>"; }
                        when "diminuendo)" | ">)" { $suffix ~= "\\!"; }
                        when /^p+$/ | "mp" | "mf" | /^f+$/ | "fermata" | "accent" | "trill" | "sfz" | "marcato"
                                 { $suffix ~= "\\" ~ $element.value; }
                        $*ERR.say: "Unrecognized gracing: " ~ $element.value.perl;
                        %unrecognized_gracings{~$element.value} = 1;
                    }
                }
                when "barline" {
                    $notes ~= self.WrapBar($lilypond, $duration, :beginning($first-time));
                    $first-time = False;
                    if $element.value eq "||" {
                        $notes ~= ' \\bar "||"';
                    } else {
                        $notes ~= ' \\bar "|"';
                    }
                    $notes ~= "\n";
                    $lilypond = "";
                    $duration = 0;
                    $.context.bar-line;
                }
                when "inline_field" {
                    given $element.value.key {
                        when "K" { 
                            $!context = LilypondContext.new($element.value.value, 
                                                            $!context.context.meter, 
                                                            $!context.context.length,
                                                            :current-key-info($!context.context.key-info)); 
                            $lilypond ~= $!context.key-to-string;
                            $lilypond ~= $!context.clef-to-string;
                        }
                        when "M" {
                            $!context = LilypondContext.new($!context.context.key-name,
                                                            $element.value.value,
                                                            $!context.context.length);
                            $lilypond ~= $!context.meter-to-string;
                        }
                        when "L" {
                            $!context = LilypondContext.new($!context.context.key-name,
                                                            $!context.context.meter,
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
                            $suffix ~= '^' ~ $chord_or_text ~ " ";
                        } else {
                            given $element.value {
                                when /^ '^'(.*)/ { $suffix ~= '^"' ~ $0 ~ '" ' }
                            }
                        }
                    }
                }
                when "grace_notes" {
                    $*ERR.say: "Unused suffix in grace note code: $suffix" if $suffix;
                    
                    $lilypond ~= $element.value.acciaccatura ?? "\\acciaccatura \{" !! "\\grace \{";
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
                when "spacing" { $lilypond ~= $spacing-comment }
                when "endline" { $lilypond ~= "\\break \\noPageBreak" if $use-ABC-line-breaks; }
                # .say;
            }
        }
    
        $out.say: "\{";
        $notes ~= self.WrapBar($lilypond, $duration, :beginning($first-time));
        $first-time = False;
        $out.say: $notes;
        $out.say: " \}";
    }
    
    method BodyToLilypond(@elements, $out, :$prefix?) {
        $out.say: "\{";
        $out.say: $prefix if $prefix;

        # if tune contains M: none sections, turn off barnumber display
        if @elements.grep({ $_.key eq "inline_field" && $_.value.key eq "M" && $_.value.value eq "none" }) {
            $out.say: "\\override Score.BarNumber.break-visibility = ##(#f #f #f)";
        }

        $out.print: $.context.key-to-string;
        $out.say: "\\accidentalStyle modern-cautionary";
        $out.print: $.context.clef-to-string;
        $out.print: $.context.meter-to-string;
        
        my $first-time = True;
    
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
                self.SectionToLilypond(@elements[$start-of-section ..^ $i], $out, :beginning($first-time));
                $first-time = False;
                $start-of-section = $i + 1;
                given @elements[$i].value {
                    when '||' { $out.say: '\\bar "||"'; }
                    when '|]' { $out.say: '\\bar "|."'; }
                }
            }

            if @elements[$i].key eq "nth_repeat" {
                my $final-bar = "";
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
                    $final-bar = @elements[$i].value if $i < +@elements && @elements[$i].value eq '|]' | '||';
                }
                $out.say: "\}";
                
                given $final-bar {
                    when '||' { $out.say: '\\bar "||"'; }
                    when '|]' { $out.say: '\\bar "|."'; }
                }
                
            }
        }
    
        if $start-of-section + 1 < @elements.elems {
            if @elements[*-1].value eq ':|:' | ':|' | '::' {
                $out.print: "\\repeat volta 2 "; # 2 is abitrarily chosen here!
            }
            self.SectionToLilypond(@elements[$start-of-section ..^ +@elements], $out, :beginning($first-time));
            $first-time = False;
            if @elements[*-1].value eq '|]' {
                $out.say: '\\bar "|."';
            }
        }

        if @elements.grep({ $_.key eq "barline" })[*-1].value eq '|]' {
            $out.say: '\\bar "|."';
        }
    
        $out.say: "\}";
    }
    
}

sub TuneBodyToLilypondStream($tune, $out, :$prefix?) is export {
    my $key = $tune.header.get-first-value("K");
    my $meter = $tune.header.get-first-value("M");
    my $length = $tune.header.get-first-value("L") // default-length-from-meter($meter);
    my $convertor = TuneConvertor.new($key, $meter, $length);
    $convertor.BodyToLilypond($tune.music, $out, :$prefix);
}

sub HeaderToLilypond(ABC::Header $header, $out, :$title?) is export {
    dd $title;
    $out.say: "\\header \{";
    
    my $working-title = $title // $header.get-first-value("T") // "Unworking-titled";
    dd $working-title;
    $working-title = sanitize-quotation-marks($working-title);
    $out.say: "    title = \" $working-title \"";
    my $composer = sanitize-quotation-marks(get-field-if-there($header, "C"));
    my $origin = sanitize-quotation-marks(get-field-if-there($header, "O"));
    if $origin {
        if $origin ~~ m:i/^for/ {
            $out.say: qq/    dedication = "$origin"/;
        } else {
            if $composer {
                $composer ~= " ($origin)";
            } else {
                $composer = $origin;
            }
        }
    }
    $out.say: qq/    composer = "{ sanitize-quotation-marks($composer) }"/ if $composer;
    $out.say: "    subtitle = ##f";

    $out.say: "}";
}

sub tune-to-score($tune, $out) is export {
    $*ERR.say: "Working on { $tune.header.get-first-value("T") // $tune.header.get-first-value("X") }";
    $out.say: "\\score \{";

        TuneBodyToLilypondStream($tune, $out);
        HeaderToLilypond($tune.header, $out);

    $out.say: "}\n\n";
    
    if $tune.header.get-first-value("N") {
        
        for $tune.header.get("N") -> $note {
            next if $note.value ~~ / ^ \s* $ /;
            
            $out.say: q:to/END/;
                \noPageBreak
                \markup \fill-line {
                    \center-column \wordwrap-lines {
                END
                
            $out.say: "        " ~ sanitize-quotation-marks($note.value);

            $out.say: q:to/END/;
                    }
                }
                
                END
        }
        
#         $out.say: "    \\vspace #2";
    }
}

sub GetUnrecognizedGracings() is export {
    %unrecognized_gracings
}

sub add-substitute($look-for, $replace-with) is export {
    %substitutes{$look-for} = $replace-with;
}

