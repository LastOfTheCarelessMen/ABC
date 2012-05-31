package ABC::Utils {
    sub ElementToStr($element-pair) is export { 
        given $element-pair.key {
            when "gracing" {
                given $element-pair.value {
                    when '.' | '~' { $element-pair.value; }
                    '+' ~ $element-pair.value ~ '+';
                }
            }
            when "inline_field" { '[' ~ $element-pair.value.key ~ ':' ~ $element-pair.value.value ~ ']'; }
            when "chord_or_text" { '"' ~ $element-pair.value ~ '"'; }
            ~$element-pair.value;
        }
    }
}


