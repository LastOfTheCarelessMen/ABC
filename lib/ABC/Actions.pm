use v6;

use ABC::Header;
use ABC::Tune;
use ABC::Duration;
use ABC::Note;
use ABC::Rest;
use ABC::Tuplet;
use ABC::BrokenRhythm;


class ABC::Actions {
    method header_field($/) {
        make ~$<header_field_name> => ~$<header_field_data>;
    }
    
    method header($/) { 
        my $header = ABC::Header.new;
        for @( $<header_field> ) -> $field {
            $header.add-line($field.ast.key, $field.ast.value);
        }
        make $header;
    }
    
    method note_length($/) {
        if $<note_length_denominator> {
            make duration-from-parse($<top>[0], $<note_length_denominator>[0]<bottom>[0]);
        } else {
            make duration-from-parse($<top>[0]);
        }
    }
    
    method mnote($/) {
        make ABC::Note.new(~$<pitch>, 
                           $<note_length>.ast, 
                           $<tie> eq '-');
    }
    
    method stem($/) {
        if @( $<mnote> ) == 1 {
            make $<mnote>[0].ast;
        } else {
            make ABC::Stem.new(@( $<mnote> )>>.ast);
        }
    }
    
    method rest($/) {
        make ABC::Rest.new(~$<rest_type>, $<note_length>.ast);
    }
    
    method tuplet($/) {
        make ABC::Tuplet.new(3, @( $<stem> )>>.ast);
    }
    
    method broken_rhythm($/) {
        make ABC::BrokenRhythm.new($<stem>[0].ast, 
                                   ~$<g1>, 
                                   ~$<broken_rhythm_bracket>, 
                                   ~$<g2>,
                                   $<stem>[1].ast);
    }

    method inline_field($/) {
        make ~$/<alpha> => ~$/<value>;
    }
    
    method long_gracing($/) {
        make ~$/<long_gracing_text>;
    }

    method gracing($/) {
        make $/<long_gracing> ?? $/<long_gracing>.ast !! ~$/;
    }

    method element($/) {
        my $type;
        for <broken_rhythm stem rest slur_begin slur_end gracing grace_notes nth_repeat end_nth_repeat spacing tuplet inline_field> {
            $type = $_ if $/{$_};
        }
        
        my $ast = $type => ~$/{$type};
        # say :$ast.perl;
        # say $/{$type}.ast.perl;
        # say $/{$type}.ast.WHAT;
        if $/{$type}.ast ~~ ABC::Duration || $/{$type}.ast ~~ Pair | Str {
            $ast = $type => $/{$type}.ast;
        }
        make $ast;
    }
    
    method barline($/) { 
        make "barline" => ~$/;
    }
    
    method bar($/) {
        my @bar = @( $<element> )>>.ast;
        @bar.push($<barline>>>.ast);
        make @bar;
    }
    
    method line_of_music($/) {
        my @line = $<barline>>>.ast;
        my @bars = @( $<bar> )>>.ast;
        for @bars -> $bar {
            for $bar.list {
                @line.push($_);
            }
        }
        @line.push("endline" => "");
        make @line;
    }
    
    method music($/) {
        my @music;
        for @( $<line_of_music> )>>.ast -> $line {
            for $line.list {
                @music.push($_);
            }
        }
        make @music;
    }
    
    method tune($/) {
        make ABC::Tune.new($<header>.ast, $<music>.ast);
    }
    
    method tune_file($/) {
        make @( $<tune> )>>.ast;
    }
}