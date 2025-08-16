package Perlox::Interpreter::Types::Span;

=encoding utf8
=head1 Brief description

    Represents a span, a pair of indexes in a source code.

=cut

use v5.24;
use strict;
use warnings;
use utf8;

use Class::Tiny qw(start end);

use overload '""' => sub {
    my ($self) = @_;
    return sprintf('(%s..%s)', $self->start // '', $self->end // '');
};

1;