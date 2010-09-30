use v6;

use ABC::Header;
use ABC::Tune;

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
    
    method element($/) {
        my $type;
        for <broken_rhythm stem rest gracing grace_notes nth_repeat end_nth_repeat spacing> {
            $type = $_ if $/{$_};
        }
        make $type => ~$/{$type};
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