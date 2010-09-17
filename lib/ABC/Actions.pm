use v6;

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
        make [ @( $<element> )>>.ast, $<barline>>>.ast ];
    }
    
}