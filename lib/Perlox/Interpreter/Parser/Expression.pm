package Perlox::Interpreter::Parser::Expression;

=encoding utf8
=head1 Brief description

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);

sub new($class, %args) {
    return bless({%args}, $class);
}

1;