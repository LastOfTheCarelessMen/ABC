use v6;
use Test;
use ABC::Header;

plan *;

isa_ok ABC::Header.new, ABC::Header, "Can create ABC::Header object";

{
    my $a = ABC::Header.new;
    $a.add-line("X", 1);
    is $a.lines.elems, 1, "One line now present in ABC::Header";
    
    $a.add-line("T", "The Star of Rakudo");
    $a.add-line("T", "Michaud's Favorite");
    is $a.lines.elems, 3, "Three lines now present in ABC::Header";
    
    is $a.get("T").elems, 2, "Two T lines found";
    is $a.get("T")[0].value, "The Star of Rakudo", "First title correct";
    is $a.get("T")[1].value, "Michaud's Favorite", "Second title correct";
    
    

}

done_testing;
