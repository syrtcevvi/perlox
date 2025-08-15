package Perlox::Interpreter::Scanner::Error;

=encoding utf8
=head1 Brief description

    Represents an error than occurs on the scanning stage.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use lib::abs '../../../';

use Moose;
use MooseX::StrictConstructor;
use Types::Standard qw(Int Str);

use Perlox::Interpreter::Types::Span ();

use overload
    '""' => \&_to_string;

has 'message' => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has 'type' => (
    is => 'ro',
    isa => Int,
    required => 1,
);
has 'line' => (
    is => 'ro',
    isa => Int,
    required => 1,
);
has 'span' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Span',
    required => 1,
);

sub _to_string {
    my ($self) = @_;

    return sprintf(
        '%s, at line %d, column: %d',
        $self->message, $self->line,
        $self->span->start,
    );
}

__PACKAGE__->meta->make_immutable;

1;