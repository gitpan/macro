#!perl -w

use strict;

use Test::More tests => 6;

use FindBin qw($Bin);
use lib "$Bin/tlib";

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 1 }
use macro;

is(macro::->backend, 'macro::filter', 'using macro::filter');

use Foo;
use Bar;

sub _f{
	'Baz';
}

is Foo::f(), 'Foo::f', 'Foo::f()';
is Foo::g(), 'Foo::g', 'Foo::g()';
is Bar::f(), 'Bar::f', 'Bar::f()';
is Bar::g(), 'Bar::g', 'Bar::g()';

is _f(),     'Baz';

