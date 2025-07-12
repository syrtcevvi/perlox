package Perlox::Interpreter::Token;

=encoding utf8
=head1 Brief description

    Represents the token

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../..';
use experimental 'signatures';

use Readonly qw(Readonly);

BEGIN {
    use Perlox::Interpreter::Token::Type ();
    # Allows us to save some typing when working with TokenTypes
    *TokenType:: = *Perlox::Interpreter::Token::Type::;
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

sub new($class, %args) {
    return bless({
        type => $args{type},
        span => $args{span},
        line => $args{line},
        value => $args{value},
    }, $class);
}

sub _to_string {
    my ($self) = @_;

    my $string_representation = $TOKEN_TYPE_TO_STRING{$self->{type}};
    if ($self->{type} == TokenType::STRING) {
        $string_representation .= ' "' . $self->{value} . '"';
    } elsif ($self->{type} == TokenType::NUMBER) {
        $string_representation .= ' ' . $self->{value};
    }

    return $string_representation;
}

1;