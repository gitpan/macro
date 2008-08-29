package macro;

use 5.008_001;

use strict;
use warnings;
use warnings::register;

use Scalar::Util (); # tainted()
use Carp ();

our $VERSION = '0.01';

use constant DEBUG => $ENV{PERL_MACRO_DEBUG} || 0;

use PPI::Lexer;
my $lexer = PPI::Lexer->new();

my $backend;

if(DEBUG >= 1 and !$^C){
	require macro::filter;
	$backend = 'macro::filter';
}
else{
	require macro::compiler;
	$backend = 'macro::compiler';
}
sub import{
	my $class = shift;

	return unless @_;

	$backend->import(@_);

	return;
}

sub backend{ $backend }

sub new{
	my($class) = @_;

	return bless {} => $class;
}

sub defmacro{
	my $self = shift;

	while(my($name, $macro) = splice @_, 0, 2){
		if( (not defined $name) or (not defined $macro) ){
			warnings::warnif(q{Illigal declaration of macro});
			next;
		}
		if(exists $self->{$name}){
			warnings::warnif(qq{Macro "$name" redefined});
		}

		if(ref($macro) eq 'CODE'){
			if(defined prototype $macro){
				warnings::warnif(q{Macros allow no prototypes});
			}
			$macro = _deparse($macro);
		}
		else{
			if(Scalar::Util::tainted($macro)){
				return Carp::croak('Insecure dependency in macro::defmacro()');
			}
			$macro .= ' '; # lex_source() refuses empty strings
		}

		my $mdoc = $lexer->lex_source( $self->process($macro) );

		$mdoc->prune(\&_want_useless_fragment);
		warn $@ if $@;

		$self->{$name} = $mdoc;
	}

	return;
}

sub _deparse{
	my($coderef) = @_;

	our $_deparser;
	unless($_deparser){
		require B::Deparse;

		$_deparser = B::Deparse->new('-si1');
		$_deparser->ambient_pragmas(
			map{ $_ => 'all' } qw(
				strict warnings utf8 re
			)
		);
	}

	return 'do'.$_deparser->coderef2text($coderef);
}

sub _want_useless_fragment{
	my $elem = $_[1];

	# newline
	return $elem->isa('PPI::Token::Whitespace') && $elem->content eq "\n";
}

sub preprocess{
	$_[1];# noop
}
sub postprocess{
	$_[1]; # noop
}

sub process{
	my($self, $src) = @_;

	my $d = $lexer->lex_source($src);

	$d = $self->preprocess($d) or return;

	$d->{macro} = $self;
	my $words = $d->find(\&_want_macrocall);
	delete $d->{macro};

	if($words){
		foreach my $word(reverse @$words){
			$self->_expand($word);
		}
	}
	elsif($@){
		warn $@;
	}

	$d = $self->postprocess($d) or return;

	return $d->serialize();
}
# find 'foo(...)', but not 'Foo->foo(...)'
sub _want_macrocall{
	my($doc, $elem) = @_;

	if($elem->isa('PPI::Token::Word') && exists $doc->{macro}{$elem->content}){
		my $sibling = $elem->sprevious_sibling;
		if($sibling){ # check "->foo" pattern
			return 0 if
				$sibling->isa('PPI::Token::Operator')
					&& $sibling->content eq '->';
		}

		# check argument list, e.g. "foo(...)"
		$sibling = $elem->snext_sibling;
		return $sibling && $sibling->isa('PPI::Structure::List');
	}
	return 0;
}

sub _list{
	my($element) = @_;

	my $open = PPI::Token::Structure->new( '(' );
	my $list = PPI::Structure::List->new($open);

	$list->_set_finish( PPI::Token::Structure->new(')') );

	$list->add_element($element) if $element;

	return $list;
}



sub _expand{
	my($self, $word) = @_;

	my $md = $self->{ $word->content };

	# extracting arguments
	my @args;
	my $args_list = $word->snext_sibling->clone(); # Structure::List

	my $list = $args_list->schild(0); # Statement::Expression

	if($list){
		my $token = $list->schild(0);

		my $expr = PPI::Statement::Expression->new();

		while($token){
			# find ','
			if($token->isa('PPI::Token::Operator')
				and ( $token->content eq ',' or $token->content eq '=>') ){
				push @args, _list $expr;

				$expr = PPI::Statement::Expression->new();
			}
			else{
				$expr->add_element($token->clone());
			}
		} continue {
			$token = $token->snext_sibling;
		}
		if($expr != $args[-1]){
			push @args, _list $expr;
		}
	}

	# replacing parameters

	$md = $md->clone(); # copy the macro body
	if(my $params = $md->find(\&_want_param)){

		foreach my $param(@$params){
			_param_replace($param, \@args, $args_list);
		}
	}
	elsif($@){
		warn $@;
	}

	if(DEBUG >= 2){
		my $funcall = $word->content . $word->snext_sibling->content;
		my $replaced = $md->content;

		$funcall =~ s/^/# /msxg;

		warn "$funcall -> $replaced\n";
	}

	_funcall_replace($word, $md);

	return;
}

# $_[...]
sub _want_param{
	my $elem = $_[1];

	return 1 if $elem->isa('PPI::Token::ArrayIndex') && $elem->content eq '$#_';

	return 0 unless $elem->isa('PPI::Token::Magic'); # @_ is a magic variable

	return 1 if     $elem->content eq '@_';

	return      $elem->content eq '$_'

		&& ($elem = $elem->snext_sibling)
		&&  $elem->isa('PPI::Structure::Subscript')

		&& ($elem = $elem->schild(0))
		&&  $elem->isa('PPI::Statement::Expression')

		&& ($elem = $elem->schild(0))
		&&  $elem->isa('PPI::Token::Number');
}
sub _param_idx{
	my($elem) = @_;

	# Token::Magic Structure::SubScript Statement::Expression Token::Number
	return $elem->snext_sibling->schild(0)->schild(0)->content;
}

# $_[0] -> (expr)
# @_    -> (expr, expr, ...)
sub _param_replace{
	my($param, $args, $args_list) = @_;

	# XXX: insert_before() requires $arg->isa('PPI::Token'),
	#      but $arg->isa('PPI::Structure::List')

	$param->__insert_before(PPI::Token::Operator->new('+'));

	if($param->content eq '@_'){
		$param->__insert_before($args_list);
	}
	elsif($param->content eq '$#_'){
		my $expr = PPI::Statement::Expression->new();
		$expr->add_element( PPI::Token::Number->new($#{$args}) );
		$param->__insert_before(_list $expr);
	}
	else{ # $_[index]
		my $arg = $args->[_param_idx $param] || _list(PPI::Token::Word->new('undef'));
		$param->__insert_before( $arg );
		$param->snext_sibling->remove(); # remove Structure::Subscript

	}


	$param->remove();
	return;
}

# word(...) -> do{ ... }
sub _funcall_replace{
	my($word, $block) = @_;

	$word->__insert_before($block);
	$word->snext_sibling->remove();
	$word->remove();
	return;
}

1;
__END__


=head1 NAME

macro - An implementation of macro processor

=head1 VERSION

This document describes macro version 0.01

=head1 SYNOPSIS

	use macro add => sub{ $_[0] + $_[1] };
	say add(1, 3); # it's replaced into 'say do{ (1) + (3) };'

	use macro sum => sub{ my $sum=0; for my $v(@_){ $sum+=$v }; $sum };
	say sum(1, 2, 3); # => 6

	use macro my_if => sub{ $_[0] ? $_[1] : $_[2] };
	my_if( 0, print('true'), print('false') ); # only 'false' is printed

	# or compile only
	$ perl -c Module.pm # make Module.pmc

=head1 DESCRIPTION

The C<macro> pragma provides a sort of inline functions, 
which is like C pre-processor.

The macros are very fast (about 200% faster than subroutines), but they have
some limitations that C pre-processor's macros have, e.g. they cannot call
C<return()> expectedly, although they seem anonymous subroutines.

Try C<PERL_MACRO_DEBUG=2> if you want to know how this module works.

=head1 METHOD

=head2 macro->backend()

Returns the backend module, C<macro::filter> or C<macro::compiler>.

=head2 macro->new()

Returns an instance of macro processor, C<$macro>.

=head2 $macro->defmacro(name => sub{ ... });

Defines macros into I<$macro>.

=head2 $macro->process($source)

Processes Perl source code I<$source>, and returns processed source code.

C<new()>, C<defmacro()> and C<process()> are provided for backend modules.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 PERL_MACRO_DEBUG=value

Debug mode.

if it's == 0, C<macro::compiler> is used as the backend.

if it's >= 1, C<macro::filter> is used as the backend.

If it's >= 2, all macro expansions are reported to C<STDERR>.

=head1 INSTALL

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 DEPENDENCIES

=over 4

=item *

Perl 5.8.1 or later.

=item *

C<PPI> - Perl parser.

=item *

C<Filter::Util::Call> - Source filter utility.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-macro@rt.cpan.org/>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<macro::JA>.

L<macro::filter> - source filter backend.

L<macro::compiler> - compiler backend.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
