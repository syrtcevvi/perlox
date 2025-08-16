package Perlox::Interpreter::Types::Expression::Binary;

=encoding utf8
=head1 Brief description

    Represents an expression with a binary operation.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../../../../';
use parent 'Perlox::Interpreter::Types::Expression';

use Class::Tiny qw(lhs op rhs);

sub _get_string_view {
    my ($self, $offset) = @_;

    return $self->INDENTATION_SEQUENCE x $offset . $self->op . "[BINARY]\n"
        . $self->lhs->_get_string_view($offset + $self->OFFSET_INC)
        . $self->rhs->_get_string_view($offset + $self->OFFSET_INC);
}

1;