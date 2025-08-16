package Perlox::Interpreter::Scanner::Error;

=encoding utf8
=head1 Brief description

    Represents an error than occurs on the scanning stage.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../../../';

use Class::Tiny qw(message type line span);

use overload '""' => sub {
    my ($self) = @_;

    return sprintf(
        '%s, at line %d, column: %d',
        $self->message, $self->line,
        $self->span->start,
    );
};

1;