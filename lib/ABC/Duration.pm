use v6;

role ABC::Duration {
    has $.ticks;

    our multi sub duration-from-parse($top) is export {
        ABC::Duration.new(:ticks($top.Int || 1));
    }
    
    our multi sub duration-from-parse($top, $bottom) is export {
        if +($top // 0) == 0 && +($bottom // 0) == 0 {
            ABC::Duration.new(:ticks(1/2));
        } else {
            ABC::Duration.new(:ticks(($top.Int || 1) / ($bottom.Int || 1)));
        }
    }
    
    our method Str() {
        given $.ticks {
            when 1 { "---"; } # for debugging, should be ""
            when 1/2 { "/"; }
            when Int { .Str; }
            when Rat { .perl; }
            die "Duration must be Int or Rat, but it's { .WHAT }";
        }
    }
}
