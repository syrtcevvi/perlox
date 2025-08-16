package Perlox::Interpreter::Types::Expression;

=encoding utf8
=head1 Brief description

    Base class for expression values.

=cut

use v5.24;
use strict;
use warnings;
use utf8;

use Class::Tiny;

use constant {
    OFFSET_INC => 1,
    INDENTATION_SEQUENCE => '| ',
};

use overload '""' => sub {
    my ($self) = @_;
    return $self->_get_string_view(0);
};

1;