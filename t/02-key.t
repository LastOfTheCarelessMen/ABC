use v6;
use Test;
use ABC::Grammar;
use ABC::Utils;

{
    my %key = key_signature("D");
    is %key.elems, 2, "D has two sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
}

{
    my %key = key_signature("Dmix");
    is %key.elems, 1, "Dmix has one sharp";
    is %key<F>, "^", "F is sharp";
}

{
    my %key = key_signature("Am");
    is %key.elems, 0, "Am has no sharps or flats";
}

{
    my %key = key_signature("Ddor");
    is %key.elems, 0, "Ddor has no sharps or flats";
}

{
    my %key = key_signature("Ador");
    is %key.elems, 1, "Ador has one sharp";
    is %key<F>, "^", "F is sharp";
}

{
    my %key = key_signature("Amix");
    is %key.elems, 2, "Amix has two sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
}

{
    my %key = key_signature("C#m");
    is %key.elems, 4, "C#m has four sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
    is %key<G>, "^", "G is sharp";
    is %key<D>, "^", "D is sharp";
}

{
    my %key = key_signature("C#");
    is %key.elems, 7, "C# has seven sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
    is %key<G>, "^", "G is sharp";
    is %key<D>, "^", "D is sharp";
    is %key<A>, "^", "A is sharp";
    is %key<E>, "^", "E is sharp";
    is %key<B>, "^", "B is sharp";
}

{
    my %key = key_signature("C ^f _b");
    is %key.elems, 2, "C ^f _b has two thingees";
    is %key<F>, "^", "F is sharp";
    is %key<B>, "_", "B is flat";
}

{
    my %key = key_signature("C#m");
    is apply_key_signature(%key, ABC::Grammar.parse("f", :rule<pitch>)), "^f", "f => ^f";
    is apply_key_signature(%key, ABC::Grammar.parse("C", :rule<pitch>)), "^C", "C => ^C";
    is apply_key_signature(%key, ABC::Grammar.parse("G", :rule<pitch>)), "^G", "G => ^G";
    is apply_key_signature(%key, ABC::Grammar.parse("d", :rule<pitch>)), "^d", "d => ^d";
    is apply_key_signature(%key, ABC::Grammar.parse("_f", :rule<pitch>)), "_f", "_f => _f";
    is apply_key_signature(%key, ABC::Grammar.parse("=C", :rule<pitch>)), "=C", "=C => =C";
    is apply_key_signature(%key, ABC::Grammar.parse("^G", :rule<pitch>)), "^G", "^G => ^G";
    is apply_key_signature(%key, ABC::Grammar.parse("^^d", :rule<pitch>)), "^^d", "^^d => ^^d";
    is apply_key_signature(%key, ABC::Grammar.parse("b'", :rule<pitch>)), "b'", "b' => b'";
}


done;
