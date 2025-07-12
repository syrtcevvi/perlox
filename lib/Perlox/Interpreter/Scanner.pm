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
use Clone 'clone';
use List::Util qw(any);

use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Token ();
BEGIN {
    use Perlox::Interpreter::Token::Type ();
    # Allows us to save some typing when working with TokenTypes
    *TokenType:: = *Perlox::Interpreter::Token::Type::;
};

sub new($class) {
    my $self = bless({}, $class);
    return $self->_init();
}

sub _init($self) {
    %$self = (
        %$self,
        (
            source => [],
            offset => 0,
            line => 1,

            errors => [],

            tokens => [],
            token => {
                span => {
                    start => undef,
                    end => undef,
                },
            },
        )
    );

    return $self;
}

=head2 get_tokens($self, $source_code) -> []

    Returns the recognized tokens from the $source_code.

    In case of lexical errors, throws the exception Perlox::Interpreter::Scanner::UnexpectedCharacterException.

=cut
sub get_tokens($self, $source_code) {
    $self->{source} = [split(//, $source_code)];

    while (!$self->_is_eof()) {
        $self->_get_next_token();
    }

    if (scalar($self->{errors}->@*)) {
        Perlox::Interpreter::Scanner::UnexpectedCharacterException->throw(
            errors => $self->{errors},
        );
    }

    $self->_save_current_token(TokenType::EOF);

    my $tokens = clone($self->{tokens});
    $self->{tokens} = [];

    return $tokens;
}

sub _get_next_token($self) {
    my $next_character = $self->_consume_next_character();

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
        case if (_is_digit($next_character)) { $self->_parse_number(); }
        case ("\n") { $self->_process_new_line(); }
        case if (_is_whitespace($next_character)) {}
        default {
            $self->_save_error(sprintf('Unexpected character: \'%s\'', $next_character));
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
        $self->_save_error('You probably missed the trailing quote symbol "');
    }

    # Consume the trailing quote character
    $self->_consume_next_character();
    $self->_save_current_token(TokenType::STRING);
}

sub _parse_number($self) {

}

sub _save_current_token($self, $token_type) {
    my $value;
    if ($token_type == TokenType::STRING) {
        $value = join('', @{$self->{source}}[
            $self->{token}{span}{start} + 1 .. $self->{token}{span}{end} - 1
        ]);
    }

    push(
        $self->{tokens}->@*,
        Perlox::Interpreter::Token->new(
            type => $token_type,
            # It matters to store a lexeme value for some token types (string, numbers)
            defined($value)
                ? (value => $value) : (),
            # FIXME: It doesn't necessary to store metadata for each token
            span => clone($self->{token}{span}),
            line => $self->{line},
        ),
    );

    @{$self->{token}{span}}{qw(start end)} = (undef, undef);

    return;
}

sub _consume_next_character($self) {
    my $next_character = $self->{source}[$self->{offset}];

    if (_is_whitespace($next_character)) {
        $self->_skip_next_character();
    } else {
        if (!defined($self->{token}{span}{start})) {
            $self->{token}{span}{start} = $self->{offset};
        }
        $self->{token}{span}{end} = $self->{offset}++;
    }

    return $next_character;
}

sub _skip_next_character($self) {
    $self->{offset}++;
}

sub _process_new_line($self) {
    $self->{line}++;
    @{$self->{token}{span}}{qw(start end)} = (undef, undef);
}

sub _clear_token($self) {
    $self->{token} = {
        span => {
            start => undef,
            end => undef,
        },
        value => undef,
    };
}

sub _peek_next_character($self) {
    return $self->{source}[$self->{offset}] // '';
}

sub _is_eof($self) {
    return $self->{offset} >= scalar($self->{source}->@*);
}

sub _save_error($self, $error) {
    push(
        $self->{errors}->@*,
        {
            error => $error,
            # Column value is 1-based (like in an IDE), so it's okay to pass offset as-is
            column => $self->{offset},
            line => $self->{line},
        },
    );
}

sub _is_digit($maybe_digit) {
    return $maybe_digit =~ m/^\d$/;
}

sub _is_whitespace($maybe_whitespace) {
    $maybe_whitespace //= '';
    return any {
        $maybe_whitespace eq $_
    } (' ', "\r", "\t", "\f");
}

1;