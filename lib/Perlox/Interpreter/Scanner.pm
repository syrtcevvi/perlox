package Perlox::Interpreter::Scanner;

=encoding utf8
=head1 Brief description

    Represents the Scanner (Lexer) class, consumes the raw input (source code)
    and produces the sequence of recognized tokens (lexemes + some metadata).

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);
use lib::abs '../../';

use Syntax::Keyword::Match;
use Clone qw(clone);

use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Error ();
use Perlox::Interpreter::Token qw(%KEYWORDS);
BEGIN {
    use Perlox::Interpreter::Token::Type ();
    # Allows us to save some typing when working with token types
    *TokenType:: = *Perlox::Interpreter::Token::Type::;
    use Perlox::Interpreter::Error::Type ();
    *ErrorType:: = *Perlox::Interpreter::Error::Type::;
};
use Perlox::Interpreter::Scanner::Utils qw(
    is_digit
    is_alpha
    is_alpha_numeric
    is_whitespace
);

sub new($class, %args) {
    my $self = bless({}, $class);
    return $self->init();
}

sub init($self) {
    %$self = (
        %$self,

        source => [],
        offset => 0,
        line => 1,

        tokens => [],
        token => {
            span => {
                start => undef,
                end => undef,
            },
        },

        errors => [],
    );

    return $self;
}

=head2 get_tokens($self, $source_code) -> []

    Returns the recognized tokens from the $source_code.

    In case of scanning errors, throws the exception Perlox::Interpreter::Scanner::Exception.

=cut
sub get_tokens($self, $source_code) {
    $self->{source} = [split(//, $source_code)];

    while (!$self->_is_eof()) {
        $self->_get_next_token();
    }

    if (scalar($self->{errors}->@*)) {
        Perlox::Interpreter::Scanner::Exception->throw(
            errors => $self->{errors},
        );
    }

    $self->_save_current_token(TokenType::EOF);

    return $self->{tokens};
}

sub _get_next_token($self) {
    my $next_character = $self->_consume_next_character();

    unless (is_whitespace($next_character)) {
        $self->_start_growing_token();
    }

    match ($next_character: eq) {
        case ('(') { $self->_save_current_token(TokenType::LEFT_PAREN); }
        case (')') { $self->_save_current_token(TokenType::RIGHT_PAREN); }
        case ('{') { $self->_save_current_token(TokenType::LEFT_BRACE); }
        case ('}') { $self->_save_current_token(TokenType::RIGHT_BRACE); }
        case (',') { $self->_save_current_token(TokenType::COMMA); }
        case ('.') { $self->_save_current_token(TokenType::DOT); }
        case ('-') { $self->_save_current_token(TokenType::MINUS); }
        case ('+') { $self->_save_current_token(TokenType::PLUS); }
        case (';') { $self->_save_current_token(TokenType::SEMICOLON); }
        case ('*') { $self->_save_current_token(TokenType::STAR); }
        case ('!') {
            $self->_save_current_token(
                $self->_peek_next_character() eq '='
                    ? TokenType::BANG_EQUAL : TokenType::BANG
            );
        }
        case ('=') {
            $self->_save_current_token(
                $self->_peek_next_character() eq '='
                    ? TokenType::EQUAL_EQUAL : TokenType::EQUAL
            );
        }
        case ('<') {
            $self->_save_current_token(
                $self->_peek_next_character() eq '='
                    ? TokenType::LESS_EQUAL : TokenType::LESS
            );
        }
        case ('>') {
            $self->_save_current_token(
                $self->_peek_next_character() eq '='
                    ? TokenType::GREATER_EQUAL : TokenType::GREATER
            );
        }
        case ('/') {
            if ($self->_peek_next_character() eq '/') {
                while (
                    $self->_peek_next_character() ne "\n"
                    && !$self->_is_eof()
                ) {
                    $self->_skip_next_character();
                }
            } else {
                $self->_save_current_token(TokenType::SLASH);
            }
        }
        case ('"') { $self->_parse_string(); }
        case if (is_digit($next_character)) { $self->_parse_number(); }
        case if (is_alpha($next_character)) { $self->_parse_identifier_or_keyword(); }
        case ("\n") { $self->_process_new_line(); }
        case if (is_whitespace($next_character)) { $self->_clear_token(); }
        default {
            $self->_save_error(
                message => sprintf('Unexpected character: \'%s\'', $next_character),
                type => ErrorType::UNEXPECTED_CHARACTER,
            );
        }
    }
}

sub _parse_string($self) {
    while (
        $self->_peek_next_character() ne '"'
        && !$self->_is_eof()
    ) {
        $self->_consume_next_character();
        if ($self->_peek_next_character() eq "\n") {
            $self->{line}++;
        }
    }

    if ($self->_is_eof()) {
        $self->_save_error(
            message => 'You probably missed the trailing quote symbol "',
            type => ErrorType::MISSED_CLOSING_QUOTE,
        );
        return;
    }

    # Consume the trailing quote character
    $self->_consume_next_character();
    $self->_save_current_token(TokenType::STRING);
}

sub _parse_number($self) {
    my $is_float = 0;
    my $last_character;
    while (
        (
            is_digit($self->_peek_next_character())
            || !$is_float && $self->_peek_next_character() =~ m/\./
        )
        && !$self->_is_eof()
    ) {
        $is_float = 1 if $self->_peek_next_character() =~ m/\./;
        $last_character = $self->_consume_next_character();
    }

    if (is_alpha($self->_peek_next_character())) {
        $self->_save_error(
            message => sprintf(
                'Unexpected character after number: %s',
                $self->_peek_next_character(),
            ),
            type => ErrorType::UNEXPECTED_CHARACTER,
        );
        return;
    }

    $self->_save_current_token(TokenType::NUMBER);
}

sub _parse_identifier_or_keyword($self) {
    while (
        is_alpha_numeric($self->_peek_next_character())
        && !$self->_is_eof()
    ) {
        $self->_consume_next_character();
    }

    # TODO some checks

    $self->_save_current_token(TokenType::IDENTIFIER);
}

sub _save_current_token($self, $token_type) {
    $self->_end_growing_token();

    my $value;
    if ($token_type == TokenType::STRING) {
        $value = join('', @{$self->{source}}[
            $self->{token}{span}{start} + 1 .. $self->{token}{span}{end} - 1
        ]);
    } elsif ($token_type == TokenType::IDENTIFIER) {
        # Well, this branch is not only for identifiers, but also for the reserved words too
        # Which are subclass of the identifiers btw
        $value = join('', @{$self->{source}}[
            $self->{token}{span}{start}  .. $self->{token}{span}{end}
        ]);

        $token_type = $KEYWORDS{$value} // TokenType::IDENTIFIER;
    } elsif ($token_type == TokenType::NUMBER) {
        $value = join('', @{$self->{source}}[
            $self->{token}{span}{start}  .. $self->{token}{span}{end}
        ]);
    }

    push(
        $self->{tokens}->@*,
        Perlox::Interpreter::Token->new(
            type => $token_type,
            # Such metadata is important, it may be used in the next stages (parsing, for instance)
            span => clone($self->{token}{span}),
            # It makes sense to store a lexeme value for some token types (string, numbers, identificators)
            defined($value)
                ? (value => $value) : (),
        ),
    );

    $self->_clear_token();

    return;
}

sub _consume_next_character($self) {
    return $self->{source}[$self->{offset}++];
}

sub _start_growing_token($self) {
    $self->{token}{span}{start} = $self->{offset} - 1;
}

sub _end_growing_token($self) {
    $self->{token}{span}{end} = $self->{offset} - 1;
}

sub _skip_next_character($self) {
    $self->{offset}++;
}

sub _process_new_line($self) {
    $self->{line}++;
    $self->_clear_token();
}

sub _clear_token($self) {
    @{$self->{token}{span}}{qw(start end)} = (undef, undef);
}

sub _peek_next_character($self) {
    return $self->{source}[$self->{offset}] // '';
}

sub _is_eof($self) {
    return $self->{offset} >= scalar($self->{source}->@*);
}

sub _save_error($self, %args) {
    push(
        $self->{errors}->@*,
        Perlox::Interpreter::Error->new(
            stage => 'scanner',
            type => $args{type},
            message => $args{message},
            location => {
                span => {
                    # Column value is 1-based (like in an IDE), so it's okay to pass offset as-is
                    start => $self->{offset},
                    end => $self->{offset},
                },
                line => $self->{line},
            },
        ),
    );

    $self->_clear_token();
}

1;