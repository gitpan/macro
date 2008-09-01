#!perl -w

# PPI Document Dumper
# $ ppidump.pl -e 'print "Hello, world!\n"'
# $ ppidump.pl foo.pl

use strict;
use PPI::Lexer;
use PPI::Tokenizer;
use PPI::Dumper;

printf "$0 (PPI/$PPI::VERSION, Perl %vd)\n", $^V;

my $tokenizer;

if($ARGV[0] eq '-e'){
	shift @ARGV;
	$tokenizer = PPI::Tokenizer->new(\join ';', @ARGV);
}
else{
	$tokenizer = PPI::Tokenizer->new(@ARGV);
}

unless(ref $tokenizer){
	die 'PPI::Tokanizer: ', $tokenizer, "\n";
}

my $document = PPI::Lexer->new()->lex_tokenizer($tokenizer);


PPI::Dumper->new($document, 
	whitespace => 0,
	comments   => 0,
	locations  => 0,
)->print();

# PPI::Document provides complete() method,
# but it doesn't work as of PPI version 1.204_01
if($document->find_any(\&_want_continuation)){
	print "# structure not completed\n";
}

sub _want_continuation{
	my($document, $element) = @_;

	return $element->isa('PPI::Structure')
		&& !($element->start && $element->finish);
}
