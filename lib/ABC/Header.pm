use v6;

class ABC::Header {
    has @.lines; # array of Pairs representing each line of the ABC header
    
    our method add-line($name, $data) {
        self.lines.push($name => $data);
    }
    
    our method get($name) {
        self.lines.grep({ .key eq $name });
    }
    
    our method is-valid() {
        self.lines.elems > 1 
        && self.lines[0].key eq "X"
        && self.get("T").elems > 0
        && self.get("M").elems == 1
        && self.get("L").elems == 1
        && self.get("X").elems == 1
        && self.get("K").elems == 1
        && self.lines[*-1].key eq "K";
    }
}