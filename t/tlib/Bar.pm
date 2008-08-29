package
	Bar;

use strict;
use warnings;

use macro
	_f => sub { __PACKAGE__ . '::f' },
	_g => sub { __PACKAGE__ . '::g' };


sub f{
	_f();
}
#use macro _g => sub { __PACKAGE__ . '::g' };

sub g{
	_g();
}
1;