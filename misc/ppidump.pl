#!perl -w

# PPI Document Dumper
# $ ppidump.pl 'print "Hello, world!\n"'

use strict;
use PPI::Lexer;
use PPI::Dumper;

my $d = PPI::Lexer->new()->lex_source("@ARGV");

PPI::Dumper->new($d)->print();
