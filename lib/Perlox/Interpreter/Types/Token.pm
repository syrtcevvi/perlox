package Perlox::Interpreter::Types::Token;

=encoding utf8
=head1 Brief description

    Represents the token, which is the output of the Scanner iteration.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use lib::abs '../../../';

use Moose;
use MooseX::StrictConstructor;

use Readonly qw(Readonly);
use List::Util qw(any);

use Perlox::Interpreter::Types::NonNegativeInt ();
BEGIN {
    use Perlox::Interpreter::Types::Token::Type ();
    # Allows us to save some typing when working with TokenTypes
    *TokenType:: = *Perlox::Interpreter::Types::Token::Type::;
};

use overload
    '""' => \&_to_string;

Readonly::Hash my %TOKEN_TYPE_TO_STRING => (
    TokenType::LEFT_PAREN => '(',
    TokenType::RIGHT_PAREN => ')',
    TokenType::LEFT_BRACE => '{',
    TokenType::RIGHT_BRACE => '}',
    TokenType::COMMA => ',',
    TokenType::DOT => '.',
    TokenType::MINUS => '-',
    TokenType::PLUS => '+',
    TokenType::SEMICOLON  => ';',
    TokenType::SLASH => '/',
    TokenType::STAR => '*',

    TokenType::BANG => '!',
    TokenType::BANG_EQUAL => '!=',
    TokenType::EQUAL => '=',
    TokenType::EQUAL_EQUAL => '==',
    TokenType::GREATER => '>',
    TokenType::GREATER_EQUAL => '>=',
    TokenType::LESS => '<',
    TokenType::LESS_EQUAL => '<=',

    TokenType::IDENTIFIER => 'id:',
    TokenType::STRING => 'str:',
    TokenType::NUMBER => 'num:',

    TokenType::AND => 'and',
    TokenType::CLASS => 'class',
    TokenType::ELSE => 'else',
    TokenType::FALSE => 'false',
    TokenType::FUN => 'fun',
    TokenType::FOR => 'for',
    TokenType::IF => 'if',
    TokenType::NIL => 'nil',
    TokenType::OR => 'or',
    TokenType::PRINT => 'print',
    TokenType::RETURN => 'return',
    TokenType::SUPER => 'super',
    TokenType::THIS => 'this',
    TokenType::TRUE => 'true',
    TokenType::VAR => 'var',
    TokenType::WHILE => 'while',

    TokenType::EOF => 'eof',
);

has 'type' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::NonNegativeInt',
    required => 1,
    writer => '_set_type',
);
has 'span' => (
    is => 'ro',
    isa => 'Perlox::Interpreter::Types::Span',
    required => 1,
    writer => '_set_span',
);
has 'value' => (
    is => 'ro',
    isa => 'Maybe[Int | Str]',
    predicate => 'has_value',
    writer => '_set_value',
);

sub _to_string {
    my ($self) = @_;

    my $string_representation = $TOKEN_TYPE_TO_STRING{$self->type()};
    if ($self->type == TokenType::STRING) {
        $string_representation .= ' "' . $self->value . '"';
    } elsif (any { $self->type == $_ } (TokenType::NUMBER, TokenType::IDENTIFIER)) {
        $string_representation .= ' ' . $self->value;
    }

    # FIXME? 
    if (defined($self->span->start) && defined($self->span->end)) {
        $string_representation .= ' ' . $self->span;
    }

    return $string_representation;
}

__PACKAGE__->meta->make_immutable;

1;