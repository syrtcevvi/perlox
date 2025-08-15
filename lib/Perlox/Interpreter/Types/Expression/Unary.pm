package Perlox::Interpreter::Types::Expression::Unary;

=encoding utf8
=head1 Brief description

    Represents an expression with unary operation.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;

use Moose;
use MooseX::StrictConstructor;
extends 'Perlox::Interpreter::Types::Expression';

has 'op' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'value' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Expression',
    required => 1,
);

sub _get_string_view {
    my ($self, $offset) = @_;

    return $self->INDENTATION_SEQUENCE x $offset . $self->op . "[UNARY]\n"
        . $self->value->_get_string_view($offset + $self->OFFSET_INC);
}

__PACKAGE__->meta->make_immutable;

1;