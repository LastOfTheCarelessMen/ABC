use v6;

role ABC::Duration {
    has $.ticks;
    
    our sub duration-from-parse($top, $bottom) is export {
        if +$top == 0 && +$bottom == 0 {
            ABC::Duration.new(:ticks(1/2));
        } else {
            ABC::Duration.new(:ticks(($top.Int || 1) / ($bottom.Int || 1)));
        }
    }
    
    # MUST: function to convert Duration to string
}
