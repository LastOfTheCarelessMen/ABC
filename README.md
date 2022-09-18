# ABC

This module is a set of tools for dealing with [ABC music notation](https://abcnotation.com/wiki/abc:standard:v2.1) files in Raku (formerly known as Perl 6).  This includes a grammar for most of the notation format (the standard has a lot of twisty corners, and we do not support all of them), Raku data structures for representing them, and some useful utilities.

```raku
my $music = q:to<ABC-end>;
    X:044
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
    ABC-end

my $match = ABC::Grammar.parse($music, :rule<tune>, :actions(ABC::Actions.new));
ok $match, 'tune recognized';
isa-ok $match.ast, ABC::Tune, 'and ABC::Tune created';
ok $match.ast.header.is-valid, "ABC::Tune's header is valid";
is $match.ast.music.elems, 57, '$match.ast.music has 57 elements';
```

There are several scripts in bin/ built on the library:

* abc2ly: converts an ABC file to the Lilypond ly format, then invokes Lilypond on it to create high quality sheet music.  If you install ABC using zef you should just be able to say ```abc2ly wedding.abc```to convert ```wedding.abc``` to ```wedding.pdf``` via Lilypond file ```wedding.ly```

    NOTE: Lilypond also has an abc2ly script; last time I tried it it produced
    hideous looking output from Lilypond.  If you've got both installed, you will
    have to make sure the Raku bin of abc2ly appears first in your PATH.

* abc2book: Given an ABC file and a simple “book” instructions file (our own format), this makes a book PDF.  This uses Lilypond for music formatting, LaTeX for table of contents and index of tunes, and qpdf to stitch the results together into one file.  This is still pretty experimental, but has produced one published book, [The Fiddle Music of Newfoundland & Labrador Volume 1, Revised 2020 Edition](https://fmnl1.nltrad.ca)

* abctranspose: Simple tool for transposing ABC files.

* abcoctave: Simple tool for shifting the octave of ABC files.

