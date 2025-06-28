package Perlox::Interpreter::Scanner;

=encoding utf8
=head1 Brief description

    Represents the Scanner (Lexer) class, consumes the raw input (source code)
    and produces the sequence of recognized tokens (lexemes + some metadata).

=cut

use v5.24;
use strict;
use warnings;
use experimental qw(signatures);
use lib::abs '../../';

use Syntax::Keyword::Match;
use Clone 'clone';

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
            source_code_offset => 0,
            current_line => 1,
            current_column => 1,

            current_lexeme => {
                span => {
                    start_column => undef,
                    end => undef,
                },
            },
            errors => [],

            source_code_chars => [],
            tokens => [],
        )
    );

    return $self;
}

=head2 get_tokens($self, $source_code) -> []
=cut
sub get_tokens($self, $source_code) {
    $self->{source_code_chars} = [split(//, $source_code)];

    while (!$self->_is_eof()) {
        $self->_scan_token();
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

sub _scan_token($self) {
    my $current_char = $self->_get_next_char();

    match ($current_char: eq) {
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
        case ("\n") { $self->_process_new_line(); }
        default {
            push(
                $self->{errors}->@*,
                {
                    error => sprintf('Unexpected character: \'%s\'', $current_char),
                    unexpected_character => $current_char,
                    column => $self->{current_column} - 1,
                    line => $self->{current_line},
                },
            );
        }
    }
}

sub _save_current_token($self, $token_type) {
    push(
        $self->{tokens}->@*,
        Perlox::Interpreter::Token->new(
            token_type => $token_type,
            span => clone($self->{current_lexeme}{span}),
            line => $self->{current_line},
        ),
    );
    $self->{current_lexeme}{span} = {
        start_column => undef,
        end => undef,
    };

    return;
}

sub _get_next_char($self) {
    my $next_char = $self->{source_code_chars}[$self->{source_code_offset}++];

    my $previous_column = $self->{current_column}++;
    if (!defined($self->{current_lexeme}{span}{start_column})) {
        $self->{current_lexeme}{span}{start_column} = $previous_column;
    }
    $self->{current_lexeme}{span}{end} = $previous_column;

    return $next_char;
}

sub _process_new_line($self) {
    $self->{current_line}++;
    $self->{current_column} = 1;
}

sub _is_eof($self) {
    return $self->{source_code_offset} >= scalar($self->{source_code_chars}->@*);
}

1;