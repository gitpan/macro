use strict;
use warnings;
use inc::Module::Install;

name 'macro';

all_from 'lib/macro.pm';

requires 'PPI'                => 1.20;
requires 'Filter::Util::Call' => 1.06;

test_requires 'Test::Warn' => 0.11;

WriteAll;
