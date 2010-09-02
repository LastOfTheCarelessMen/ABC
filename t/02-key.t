use v6;
use Test;
use ABC;

plan *;

{
    my %key = ABC::key_signature("D");
    is %key.elems, 2, "D has two sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
}

{
    my %key = ABC::key_signature("Dmix");
    is %key.elems, 1, "Dmix has one sharp";
    is %key<F>, "^", "F is sharp";
}

{
    my %key = ABC::key_signature("Am");
    is %key.elems, 0, "Am has no sharps or flats";
}

{
    my %key = ABC::key_signature("Ddor");
    is %key.elems, 0, "Ddor has no sharps or flats";
}

{
    my %key = ABC::key_signature("Ador");
    is %key.elems, 1, "Ador has one sharp";
    is %key<F>, "^", "F is sharp";
}

{
    my %key = ABC::key_signature("Amix");
    is %key.elems, 2, "Amix has two sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
}

{
    my %key = ABC::key_signature("C#m");
    is %key.elems, 4, "C#m has four sharps";
    is %key<F>, "^", "F is sharp";
    is %key<C>, "^", "C is sharp";
    is %key<G>, "^", "G is sharp";
    is %key<D>, "^", "D is sharp";
}

{
    my %key = ABC::key_signature("C#");
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
    my %key = ABC::key_signature("C#m");
    is ABC::apply_key_signature(%key, ABC.parse("f", :rule<pitch>)), "^f", "f => ^f";
    is ABC::apply_key_signature(%key, ABC.parse("C", :rule<pitch>)), "^C", "C => ^C";
    is ABC::apply_key_signature(%key, ABC.parse("G", :rule<pitch>)), "^G", "G => ^G";
    is ABC::apply_key_signature(%key, ABC.parse("d", :rule<pitch>)), "^d", "d => ^d";
    is ABC::apply_key_signature(%key, ABC.parse("_f", :rule<pitch>)), "_f", "_f => _f";
    is ABC::apply_key_signature(%key, ABC.parse("=C", :rule<pitch>)), "=C", "=C => =C";
    is ABC::apply_key_signature(%key, ABC.parse("^G", :rule<pitch>)), "^G", "^G => ^G";
    is ABC::apply_key_signature(%key, ABC.parse("^^d", :rule<pitch>)), "^^d", "^^d => ^^d";
    is ABC::apply_key_signature(%key, ABC.parse("b'", :rule<pitch>)), "b'", "b' => b'";
}


done_testing;