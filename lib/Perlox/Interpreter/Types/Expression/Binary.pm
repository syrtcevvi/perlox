package Perlox::Interpreter::Types::Expression::Binary;

=encoding utf8
=head1 Brief description

    Represents an expression with binary operation.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use lib::abs '../../../..';

use Moose;
use MooseX::StrictConstructor;
extends 'Perlox::Interpreter::Types::Expression';

use Perlox::Interpreter::Types::Token ();

has 'op' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Token',
    required => 1,
);
has 'lhs' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Expression',
    required => 1,
);
has 'rhs' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Expression',
    required => 1,
);

sub _get_string_view {
    my ($self, $offset) = @_;

    return $self->INDENTATION_SEQUENCE x $offset . $self->op . "[BINARY]\n"
        . $self->lhs->_get_string_view($offset + $self->OFFSET_INC)
        . $self->rhs->_get_string_view($offset + $self->OFFSET_INC);
}

__PACKAGE__->meta->make_immutable;

1;