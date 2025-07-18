package Perlox::Interpreter::Token;

=encoding utf8
=head1 Brief description

    Represents the token, which is the output of the Scanner iteration.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use lib::abs '../..';
use experimental 'signatures';

use Exporter qw(import);
use Readonly qw(Readonly);
use List::Util qw(any);

BEGIN {
    use Perlox::Interpreter::Token::Type ();
    # Allows us to save some typing when working with TokenTypes
    *TokenType:: = *Perlox::Interpreter::Token::Type::;
};

use overload
    '""' => \&_to_string;

our @EXPORT_OK = qw(%KEYWORDS);

Readonly::Hash our %KEYWORDS => (
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
    return bless({%args}, $class);
}

sub _to_string {
    my ($self) = @_;

    my $string_representation = $TOKEN_TYPE_TO_STRING{$self->{type}};
    if ($self->{type} == TokenType::STRING) {
        $string_representation .= ' "' . $self->{value} . '"';
    } elsif (any { $self->{type} == $_ } (TokenType::NUMBER, TokenType::IDENTIFIER)) {
        $string_representation .= ' ' . $self->{value};
    }

    if (defined($self->{span}{start}) && defined($self->{span}{end})) {
        $string_representation .= sprintf(' (%s..%s)', @{$self->{span}}{qw(start end)});
    }

    return $string_representation;
}

1;