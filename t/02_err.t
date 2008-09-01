#!perl -w

use strict;

use Test::More tests => 7;
use Test::Warn;

use macro::filter foo => sub{ 'foo' . $_[0] };

warning_like{
	eval q{ use macro foo => undef };
} qr/Illigal declaration/, 'Illigal declaration';

warning_like{
	eval q{ use macro undef() => sub{ 'foo' } };
} qr/Illigal declaration/, 'Illigal declaration';

warning_like{
	eval q{ use macro foo => sub{ 'FOO' }, foo => sub{ 'BAR' }; };
} qr/redefined/, 'Macro redefined';

warning_like{
	eval q{ use macro bar => sub($){ 'bar' } };
} qr/no prototypes/, 'No prototypes';

my $result;
warnings_like{
	$result = foo();
} qr/Use of uninitialized value/, 'Not enough arguments';
is $result, 'foo';

is foo('bar'), 'foobar', 'finished';

