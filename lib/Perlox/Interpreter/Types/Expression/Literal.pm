package Perlox::Interpreter::Types::Expression::Literal;

=encoding utf8
=head1 Brief description

    Represents an expression with literal value.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use lib::abs '../../../../';

use Moose;
use MooseX::StrictConstructor;
extends 'Perlox::Interpreter::Types::Expression';

use Perlox::Interpreter::Types::Token ();

has 'value' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Token',
    required => 1,
);

sub _get_string_view {
    my ($self, $offset) = @_;

    return $self->INDENTATION_SEQUENCE x $offset . $self->value . "\n";
}

__PACKAGE__->meta->make_immutable;

1;