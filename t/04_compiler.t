#!perl -w

use strict;

use Test::More tests => 6;

use FindBin qw($Bin);
use lib "$Bin/tlib";
use Fatal qw(unlink);

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 0 }
use macro;
is(macro::->backend, 'macro::compiler', 'using macro::compiler');

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

unlink("$Bin/tlib/Foo.pmc");
unlink("$Bin/tlib/Bar.pmc");
