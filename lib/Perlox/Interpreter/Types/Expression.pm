package Perlox::Interpreter::Types::Expression;

=encoding utf8
=head1 Brief description

    Base class for expression values.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;

use Moose;
use MooseX::StrictConstructor;

use constant {
    OFFSET_INC => 1,
    INDENTATION_SEQUENCE => '| ',
};

use overload
    '""' => \&_to_string;

sub _to_string {
    my ($self) = @_;
    return $self->_get_string_view(0);
}

__PACKAGE__->meta->make_immutable;

1;