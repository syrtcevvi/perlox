package Perlox::Interpreter::Types::Expression::Literal;

=encoding utf8
=head1 Brief description

    Represents an expression with literal value.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../../../../';
use parent 'Perlox::Interpreter::Types::Expression';

use Class::Tiny qw(value);

sub _get_string_view {
    my ($self, $offset) = @_;

    return $self->INDENTATION_SEQUENCE x $offset . $self->value . "\n";
}

1;