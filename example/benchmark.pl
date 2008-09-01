#!perl -w

use strict;

use Benchmark qw(:all);

BEGIN{ $ENV{PERL_MACRO_DEBUG} = 1 }
use macro add => sub{ $_[0] + $_[1] };
sub add{ $_[0] + $_[1] }

print "Benchmark of macro/$macro::VERSION\n";

cmpthese timethese -1 => {
	macro => sub{
		my $sum = 0;
		for my $i (1 .. 1000){
			$sum = add($sum, $i);
		}
	},
	sub => sub{
		my $sum = 0;
		for my $i (1 .. 1000){
			$sum = &add($sum, $i);
		}
	},
};
