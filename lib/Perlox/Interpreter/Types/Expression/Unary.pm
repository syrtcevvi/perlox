package Perlox::Interpreter::Types::Expression::Unary;

=encoding utf8
=head1 Brief description

    Represents an expression with an unary operation.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../../../../';
use parent 'Perlox::Interpreter::Types::Expression';

use Class::Tiny qw(op value);

sub _get_string_view {
    my ($self, $offset) = @_;

    return $self->INDENTATION_SEQUENCE x $offset . $self->op . "[UNARY]\n"
        . $self->value->_get_string_view($offset + $self->OFFSET_INC);
}

1;