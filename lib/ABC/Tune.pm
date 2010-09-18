use v6;
use ABC::Header;

class ABC::Tune {
    has $.header;
    has @.music;
    
    multi method new(ABC::Header $header, @music) {
        self.bless(*, :$header, :@music);
    }
    
}