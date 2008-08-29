#!perl -w

use strict;

use macro::filter
	mul => sub{ $_[0] * $_[1] },
	say => sub{ print @_, "\n" };

say('Hello, world!');

say(q{mul(1+2, 3+4) = }, mul( 1+2, 3+4 ));
