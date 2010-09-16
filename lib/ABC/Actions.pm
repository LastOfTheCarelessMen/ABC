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
}