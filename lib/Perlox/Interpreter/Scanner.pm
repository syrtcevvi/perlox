package Perlox::Interpreter::Scanner;

=encoding utf8
=head1 Brief description

    Represents the Scanner (Lexer) class. It consumes the raw input characters (source code)
    in the UTF-8 encoding and produces the sequence of recognized tokens (lexemes + some metadata).

    During the lexing stage collects found lexing errors. At the end of the stage it throws
    the Perlox::Interpreter::Scanner::Error exception with all found errors.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use experimental 'signatures';
use lib::abs '../../';

use Moose;
use MooseX::StrictConstructor;
use Syntax::Keyword::Match;
use Clone qw(clone);

use Perlox::Interpreter::Types::Token ();
BEGIN {
    use Perlox::Interpreter::Types::Token::Type ();
    # Allows us to save some typing when working with token types
    *TokenType:: = *Perlox::Interpreter::Types::Token::Type::;
    use Perlox::Interpreter::Scanner::Error::Type ();
    *ErrorType:: = *Perlox::Interpreter::Scanner::Error::Type::;
};
use Perlox::Interpreter::Types::Span ();
use Perlox::Interpreter::Scanner::Error ();
use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Scanner::Utils qw(
    is_digit
    is_alpha
    is_alpha_numeric
    is_whitespace
);

Readonly::Hash my %KEYWORDS => (
    and => TokenType::AND,
    class => TokenType::CLASS,
    else => TokenType::ELSE,
    false => TokenType::FALSE,
    for => TokenType::FOR,
    fun => TokenType::FUN,
    if => TokenType::IF,
    nil => TokenType::NIL,
    or => TokenType::OR,
    print =>TokenType::PRINT,
    return =>TokenType::RETURN,
    super =>TokenType::SUPER,
    this => TokenType::THIS,
    true => TokenType::TRUE,
    var => TokenType::VAR,
    while =>TokenType::WHILE,
);

has '_source_code_chars' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { return []; },
    init_arg => undef,
);
has '_offset' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
    init_arg => undef,
);
has '_line' => (
    is => 'rw',
    default => 1,
    init_arg => undef,
);
has '_tokens' => (
    is => 'rw',
    isa => 'ArrayRef[Perlox::Interpreter::Types::Token]',
    default => sub { return []; },
    init_arg => undef,
);
has '_span' => (
    is => 'rw',
    isa => 'Perlox::Interpreter::Types::Span',
    default => sub { return Perlox::Interpreter::Types::Span->new(start => undef, end => undef); },
    init_arg => undef,
);
has '_errors' => (
    is => 'rw',
    isa => 'ArrayRef[Perlox::Interpreter::Scanner::Error]',
    default => sub { return []; },
    init_arg => undef,
);

sub init($self) {
    $self->_source_code_chars([]);
    $self->_offset(0);
    $self->_line(1);
    $self->_tokens([]);
    $self->_clear_span();
    $self->_errors([]);
}

=head2 $self->get_tokens($source_code: Str) -> []

    Returns the recognized tokens from the $source_code.

    In case of scanning errors, throws the exception Perlox::Interpreter::Scanner::Exception
    with all found errors.

=cut
sub get_tokens($self, $source_code) {
    $self->_source_code_chars([split(m//, $source_code)]);

    while (!$self->_is_eof()) {
        $self->_get_next_token();
    }

    if (scalar($self->_errors->@*)) {
        Perlox::Interpreter::Scanner::Exception->throw(
            errors => clone($self->_errors),
        );
    }

    $self->_save_current_token(TokenType::EOF);

    return clone($self->_tokens);
}


=head2 $self->_get_next_token() -> Maybe[Perlox::Interpreter::Types::Token]

    Tries to recognize next token in the provided source code.

=cut
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
        case if (is_whitespace($next_character)) { $self->_clear_span(); }
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
            $self->_line($self->_line + 1);
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

=head2 $self->_save_current_token($token_type: Perlox::Interpreter::Types::Token::Type)
=cut
sub _save_current_token($self, $token_type) {
    $self->_end_growing_token();

    my $value;
    if ($token_type == TokenType::STRING) {
        $value = join('', @{$self->_source_code_chars}[
            $self->_token->span->start + 1 .. $self->_token->span->end - 1
        ]);
    } elsif ($token_type == TokenType::IDENTIFIER) {
        # Well, this branch is not only for identifiers, but also for the reserved words too
        # Which are subclass of the identifiers btw
        $value = join('', @{$self->_source_code_chars}[
            $self->_token->span->start  .. $self->_token->span->end
        ]);

        $token_type = $KEYWORDS{$value} // TokenType::IDENTIFIER;
    } elsif ($token_type == TokenType::NUMBER) {
        $value = join('', @{$self->_source_code_chars}[
            $self->_span->start  .. $self->_span->end
        ]);
    }

    push(
        $self->_tokens->@*,
        Perlox::Interpreter::Types::Token->new(
            type => $token_type,
            # Such metadata is important, it may be used in the next stages (parsing, for instance)
            span => clone($self->_span),
            # It makes sense to store a lexeme value for some token types (string, numbers, identificators)
            defined($value)
                ? (value => $value) : (),
        ),
    );

    $self->_clear_span();

    return;
}

sub _consume_next_character($self) {
    my $next_character = $self->_source_code_chars->[$self->_offset];
    $self->_offset($self->_offset + 1);

    return $next_character;
}

sub _start_growing_token($self) {
    $self->_span->start($self->_offset - 1);
}

sub _end_growing_token($self) {
    $self->_span->end($self->_offset - 1);
}

sub _skip_next_character($self) {
    $self->_offset($self->_offset + 1);
}

sub _process_new_line($self) {
    $self->{line}++;
    $self->_clear_span();
}

sub _clear_span($self) {
    $self->_span->start(undef);
    $self->_span->end(undef);
}

sub _peek_next_character($self) {
    return $self->_source_code_chars->[$self->_offset] // '';
}

sub _is_eof($self) {
    return $self->_offset >= scalar($self->_source_code_chars->@*);
}

sub _save_error($self, %args) {
    push(
        $self->_errors->@*,
        Perlox::Interpreter::Scanner::Error->new(
            type => $args{type},
            message => $args{message},
            span => Perlox::Interpreter::Types::Span->new(
                # Column values are 1-based (like in an IDE), so it's okay to pass offset as-is
                start => $self->_offset,
                end => $self->_offset,
            ),
            line => $self->_line,
        ),
    );

    $self->_clear_span();
}

1;