use v6;

class ABC::Header {
    has @.lines; # array of Pairs representing each line of the ABC header
    
    our method add-line($name, $data) {
        self.lines.push($name => $data);
    }
    
    our method get($name) {
        self.lines.grep({ .key eq $name });
    }
}