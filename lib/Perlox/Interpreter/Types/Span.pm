package Perlox::Interpreter::Types::Span;

=encoding utf8
=head1 Brief description

    Represents a span, a pair of indexes in a source code.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use lib::abs '../../../';

use Moose;
use MooseX::StrictConstructor;
use Carp qw(confess);

use Perlox::Interpreter::Types::NonNegativeInt ();

use overload
    '""' => \&_to_string;

has 'start' => (
    is => 'rw',
    isa => 'Maybe[Perlox::Interpreter::Types::NonNegativeInt]',
    required => 1,
    trigger => \&_confess_if_span_is_not_correct,
);
has 'end' => (
    is => 'rw',
    isa => 'Maybe[Perlox::Interpreter::Types::NonNegativeInt]',
    required => 1,
    trigger => \&_confess_if_span_is_not_correct,
);

sub _confess_if_span_is_not_correct {
    my ($self, $old, $new) = @_;

    if (
        defined($self->start)
        && defined($self->end)
        && $self->start > $self->end
    ) {
        confess(sprintf(
            'start(%d) must be lower or equal than end(%d)',
            $self->start,
            $self->end
        ));
    }
}

sub _to_string {
    my ($self) = @_;
    return sprintf('(%s..%s)', $self->start() // '', $self->end() // '');
}

__PACKAGE__->meta->make_immutable;

1;