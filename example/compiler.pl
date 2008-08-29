#!perl -w
use strict;

use macro::compiler
	add      => sub{ $_[0] + $_[1] },
	addprint => sub{ warn add($_[0], $_[1]) },
;

addprint(5, 10);
