use v6;
use Test;
use ABC::Utils;

is default-length-from-meter("4/4"),  "1/8",  "4/4 defaults to eighth note";
is default-length-from-meter("2/2"),  "1/8",  "2/2 defaults to eighth note";
is default-length-from-meter("3/4"),  "1/8",  "3/4 defaults to eighth note";
is default-length-from-meter("6/8"),  "1/8",  "6/8 defaults to eighth note";
is default-length-from-meter("2/4"),  "1/16", "2/4 defaults to sixteenth note";
is default-length-from-meter("C"),    "1/8",  "Common time defaults to eighth note";
is default-length-from-meter("C|"),   "1/8",  "Cut time defaults to eighth note";
is default-length-from-meter(""),     "1/8",  "No meter defaults to eighth note";
is default-length-from-meter("none"), "1/8",  "No meter defaults to eighth note";

done;