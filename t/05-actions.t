use v6;
use Test;
use ABC::Header;
use ABC::Grammar;
use ABC::Actions;

plan *;

{
    my $music = q«X:64
T:Cuckold Come Out o' the Amrey
S:Northumbrian Minstrelsy
M:4/4
L:1/8
K:D
»;
    my $match = ABC::Grammar.parse($music, :rule<header>, :actions(ABC::Actions.new));
    isa_ok $match, Match, 'tune recognized';
    isa_ok $match.ast, ABC::Header, '$match.ast is an ABC::Header';
    $match.ast.get("T").perl.say;
}

done_testing;