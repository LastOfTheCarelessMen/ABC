use v6;
use Test;
use ABC::Header;
use ABC::Tune;
use ABC::Grammar;
use ABC::Actions;
use ABC::Note;
use ABC::Stem;
use ABC::Rest;
use ABC::Tuplet;
use ABC::BrokenRhythm;

plan *;

{
    my $match = ABC::Grammar.parse("e3", :rule<mnote>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    isa_ok $match.ast, ABC::Note, '$match.ast is an ABC::Note';
    is $match.ast.pitch, "e", "Pitch e";
    is $match.ast.ticks, 3, "Duration 3 ticks";
}

{
    my $match = ABC::Grammar.parse("e", :rule<mnote>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    isa_ok $match.ast, ABC::Note, '$match.ast is an ABC::Note';
    is $match.ast.pitch, "e", "Pitch e";
    is $match.ast.ticks, 1, "Duration 1 ticks";
}

{
    my $match = ABC::Grammar.parse("^e,/", :rule<mnote>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    isa_ok $match.ast, ABC::Note, '$match.ast is an ABC::Note';
    is $match.ast.pitch, "^e,", "Pitch ^e,";
    is $match.ast.ticks, 1/2, "Duration 1/2 ticks";
}

{
    my $match = ABC::Grammar.parse("z/", :rule<rest>, :actions(ABC::Actions.new));
    ok $match, 'rest recognized';
    isa_ok $match.ast, ABC::Rest, '$match.ast is an ABC::Rest';
    is $match.ast.type, "z", "Rest is z";
    is $match.ast.ticks, 1/2, "Duration 1/2 ticks";
}

{
    my $match = ABC::Grammar.parse("F3/2", :rule<mnote>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    isa_ok $match.ast, ABC::Note, '$match.ast is an ABC::Note';
    is $match.ast.pitch, "F", "Pitch F";
    is $match.ast.ticks, 3/2, "Duration 3/2 ticks";
}

{
    my $match = ABC::Grammar.parse("(3abc", :rule<tuplet>, :actions(ABC::Actions.new));
    ok $match, 'tuplet recognized';
    isa_ok $match.ast, ABC::Tuplet, '$match.ast is an ABC::Tuplet';
    is $match.ast.tuple, "3", "It's a triplet";
    is $match.ast.ticks, 2, "Duration 2 ticks";
    is +$match.ast.notes, 3, "Three internal note";
    ok $match.ast.notes[0] ~~ ABC::Stem | ABC::Note, "First internal note is of the correct type";
    is $match.ast.notes, "a b c", "Notes are correct";
}

{
    my $match = ABC::Grammar.parse("a>~b", :rule<broken_rhythm>, :actions(ABC::Actions.new));
    ok $match, 'broken rhythm recognized';
    isa_ok $match.ast, ABC::BrokenRhythm, '$match.ast is an ABC::BrokenRhythm';
    is $match.ast.ticks, 2, "total duration is two ticks";
    isa_ok $match.ast.effective-stem1, ABC::Note, "effective-stem1 is a note";
    is $match.ast.effective-stem1.pitch, "a", "first pitch is a";
    is $match.ast.effective-stem1.ticks, 1.5, "first duration is 1 + 1/2";
    isa_ok $match.ast.effective-stem2, ABC::Note, "effective-stem2 is a note";
    is $match.ast.effective-stem2.pitch, "b", "first pitch is a";
    is $match.ast.effective-stem2.ticks, .5, "second duration is 1/2";
}

{
    my $match = ABC::Grammar.parse("a<<<b", :rule<broken_rhythm>, :actions(ABC::Actions.new));
    ok $match, 'broken rhythm recognized';
    isa_ok $match.ast, ABC::BrokenRhythm, '$match.ast is an ABC::BrokenRhythm';
    is $match.ast.ticks, 2, "total duration is two ticks";
    isa_ok $match.ast.effective-stem1, ABC::Note, "effective-stem1 is a note";
    is $match.ast.effective-stem1.pitch, "a", "first pitch is a";
    is $match.ast.effective-stem1.ticks, 1/8, "first duration is 1/8";
    isa_ok $match.ast.effective-stem2, ABC::Note, "effective-stem2 is a note";
    is $match.ast.effective-stem2.pitch, "b", "first pitch is a";
    is $match.ast.effective-stem2.ticks, 15/8, "second duration is 1 + 7/8";
}

{
    my $match = ABC::Grammar.parse("[K:F]", :rule<element>, :actions(ABC::Actions.new));
    ok $match, 'inline field recognized';
    # isa_ok $match.ast, ABC::BrokenRhythm, '$match.ast is an ABC::BrokenRhythm';
    is $match<inline_field><alpha>, "K", "field type is K";
    is $match<inline_field><value>, "F", "field value is K";
}

{
    my $match = ABC::Grammar.parse("+fff+", :rule<long_gracing>, :actions(ABC::Actions.new));
    ok $match, 'long gracing recognized';
    isa_ok $match.ast, Str, '$match.ast is a Str';
    is $match.ast, "fff", "gracing is fff";
}

{
    my $match = ABC::Grammar.parse("+fff+", :rule<gracing>, :actions(ABC::Actions.new));
    ok $match, 'long gracing recognized';
    isa_ok $match.ast, Str, '$match.ast is a Str';
    is $match.ast, "fff", "gracing is fff";
}

{
    my $match = ABC::Grammar.parse("~", :rule<gracing>, :actions(ABC::Actions.new));
    ok $match, 'gracing recognized';
    isa_ok $match.ast, Str, '$match.ast is a Str';
    is $match.ast, "~", "gracing is ~";
}

{
    my $match = ABC::Grammar.parse("+fff+", :rule<element>, :actions(ABC::Actions.new));
    ok $match, 'long gracing recognized';
    is $match.ast.key, "gracing", '$match.ast.key is gracing';
    isa_ok $match.ast.value, Str, '$match.ast.value is a Str';
    is $match.ast.value, "fff", "gracing is fff";
}

{
    my $music = q«X:64
T:Cuckold Come Out o' the Amrey
S:Northumbrian Minstrelsy
M:4/4
L:1/8
K:D
»;
    my $match = ABC::Grammar.parse($music, :rule<header>, :actions(ABC::Actions.new));
    ok $match, 'tune recognized';
    isa_ok $match.ast, ABC::Header, '$match.ast is an ABC::Header';
    is $match.ast.get("T").elems, 1, "One T field found";
    is $match.ast.get("T")[0].value, "Cuckold Come Out o' the Amrey", "And it's correct";
    ok $match.ast.is-valid, "ABC::Header is valid";
}

{
    my $match = ABC::Grammar.parse("e3", :rule<element>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    isa_ok $match.ast, Pair, '$match.ast is a Pair';
    is $match.ast.key, "stem", "Stem found";
    isa_ok $match.ast.value, ABC::Note, "Value is note";
}

{
    my $match = ABC::Grammar.parse("G2g gdc|", :rule<bar>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    is $match.ast.elems, 7, '$match.ast has seven elements';
    is $match.ast[3].key, "stem", "Fourth is stem";
    is $match.ast[*-1].key, "barline", "Last is barline";
}

{
    my $match = ABC::Grammar.parse("G2g gdc", :rule<bar>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
    is $match.ast.elems, 6, '$match.ast has six elements';
    is $match.ast[3].key, "stem", "Fourth is stem";
    is $match.ast[*-1].key, "stem", "Last is stem";
}

{
    my $music = q«BAB G2G|G2g gdc|BAB G2G|=F2f fcA|
BAB G2G|G2g gdB|c2a B2g|A2=f fcA:|
»;

    my $match = ABC::Grammar.parse($music, :rule<music>, :actions(ABC::Actions.new));
    ok $match, 'element recognized';
#     say $match.ast.perl;
    is $match.ast.elems, 57, '$match.ast has 57 elements';
    # say $match.ast.elems;
    # say $match.ast[28].WHAT;
    # say $match.ast[28].perl;
    is $match.ast[28].key, "endline", "29th is endline";
    is $match.ast[*-1].key, "endline", "Last is endline";
}

{
    my $music = q«X:044
T:Elsie Marley
B:Robin Williamson, "Fiddle Tunes" (New York 1976)
N:"printed by Robert Petrie in 1796 and is
N:"described by him as a 'bumpkin'."
Z:Nigel Gatherer
M:6/8
L:1/8
K:G
BAB G2G|G2g gdc|BAB G2G|=F2f fcA|
BAB G2G|G2g gdB|c2a B2g|A2=f fcA:|
»;

    my $match = ABC::Grammar.parse($music, :rule<tune>, :actions(ABC::Actions.new));
    ok $match, 'tune recognized';
    isa_ok $match.ast, ABC::Tune, 'and ABC::Tune created';
    ok $match.ast.header.is-valid, "ABC::Tune's header is valid";
    is $match.ast.music.elems, 57, '$match.ast.music has 57 elements';
}

{
    my $match = ABC::Grammar.parse(slurp("samples.abc"), :rule<tune_file>, :actions(ABC::Actions.new));
    ok $match, 'samples.abc is a valid tune file';
    # say $match.ast.perl;
    is @( $match<tune> ).elems, 3, "Three tunes were found";
    # is @( $match.ast )[0].elems, 3, "Three tunes were found";
    isa_ok @( $match.ast )[0][0], ABC::Tune, "First is an ABC::Tune";
}

done;
