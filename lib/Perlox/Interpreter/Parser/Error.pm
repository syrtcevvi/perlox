package Perlox::Interpreter::Parser::Error;

=encoding utf8
=head1 Brief description

    Represents an error that occurs on the parsing stage.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../../../';

use Syntax::Keyword::Match;

use Perlox::Interpreter::Types::Span ();
BEGIN {
    use Perlox::Interpreter::Parser::Error::Type ();
    *ErrorType:: = *Perlox::Interpreter::Parser::Error::Type::;
};

use Class::Tiny qw(message type line last_token_span);

use overload '""' => sub {
    my ($self) = @_;

    match ($self->type : ==) {
        case (ErrorType::UNEXPECTED_EOI) {
            # TODO
        } case(ErrorType::MISSED_CLOSING_PAREN) {
            return sprintf(
                '%s, at line %d, column: %d',
                $self->message, $self->line,
                # Span values are 0-based (like indexes), and we need the next place right after the last token
                # So, it's + 2
                $self->last_token_span->end + 2,
            );
        } default {
            return sprintf(
                '%s, at line %d, column: %d',
                $self->message, $self->line,
                $self->last_token_span->start,
            );
        }
    }
};

1;