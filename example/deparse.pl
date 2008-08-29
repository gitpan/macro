#!perl -w
use strict;

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 2 }
use macro::filter
	add    => sub{ $_[0] + $_[1] },
	square => sub{ $_[0] + $_[0] },
	say    => sub{ print @_, "\n" };

print add(10-1, (1, 2)), "\n";
print square(10), "\n";

say();
say("foo");
say("foo", "bar");
