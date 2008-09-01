#!perl -w
use strict;

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 2 }
use macro::filter
	add    => sub{ $_[0] + $_[1] },
	square => sub{ $_[0] + $_[0] },
	say    => sub{ print @_, "\n" };

say( add(10-1, (1, 2)) );
say( square(10) );

say();
say("foo");
say("foo", "bar");
