#!perl -wT

use strict;

use Test::More tests => 3;

my $tainted = substr($^X, 0, 0); # safe tainted string

require macro;

my $macro = macro->new();

ok eval{
	$macro->defmacro(foo => ''); 1;
}, 'untainted';

ok !eval{
	$macro->defmacro(bar => $tainted); 1
}, 'died on insecure dependency';

like $@, qr/Insecure dependency/, 'errstr: insecure dependency';
