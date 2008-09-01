#!perl -w

use strict;

use Test::More tests => 10;

use FindBin qw($Bin);
use lib "$Bin/tlib";

BEGIN{
	unlink "$Bin/tlib/Foo.pmc";
	unlink "$Bin/tlib/Bar.pmc";

	$ENV{PERL_MACRO_DEBUG} = 0;
}
use Fatal qw(unlink);

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


is Foo::h(), 'func', 'lexicality in Foo';
is Bar::h(), 'func', 'lexicality in Bar';


is Foo::line(), Foo::correct_line(), 'Foo: correct lineno';
is Bar::line(), Bar::correct_line(), 'Bar: correct lineno';

is _f(),     'Baz', 'file scoped';

unlink("$Bin/tlib/Foo.pmc");
unlink("$Bin/tlib/Bar.pmc");
