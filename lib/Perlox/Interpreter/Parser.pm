package Perlox::Interpreter::Parser;

=encoding utf8
=head1 Brief description

    Represents the Parser class for the Lox language. It's implemented via a
    Recursive Descent technique.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);
use lib::abs '../../';

use List::Util qw(any);

use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Parser::Expression ();
BEGIN {
    use Perlox::Interpreter::Token::Type ();
    # Allows us to save some typing when working with token types
    *TokenType:: = *Perlox::Interpreter::Token::Type::;
    use Perlox::Interpreter::Parser::Expression::Type ();
    *ExpressionType:: = *Perlox::Interpreter::Parser::Expression::Type::;
};

sub new($class, %args) {
    my $self = bless({}, $class);
    return $self->init();
}

sub init($self) {
    %$self = (
        %$self,

        tokens => [],
        offset => 0,

        errors => [],
    );
    return $self;
}

sub parse($self, $tokens) {
    $self->{tokens} = $tokens;

    my $expr = $self->_parse_expression();

    if (scalar($self->{errors}->@*)) {
        Perlox::Interpreter::Parser::Exception->throw(
            errors => $self->{errors},
        );
    }

    return $expr;
}

sub _parse_expression($self) {
    return $self->_parse_equality();
}

# It's a bit strange to separate the _parse_equality(==, !=) and _parse_comparison(>, >=, <, <=) to different
# precedence levels, but this is the way the author of the book took, so it's okay
sub _parse_equality($self) {
    my $expr = $self->_parse_comparison();

    while (my $op = $self->_match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)) {
        my $rhs = $self->_parse_comparison();
        $expr = Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::BINARY,
            lhs => $expr,
            op => $op,
            rhs => $rhs,
        );
    }

    return $expr;
}

sub _parse_comparison($self) {
    my $expr = $self->_parse_term();

    while (my $op = $self->_match(
        TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL
    )) {
        my $rhs = $self->_parse_term();
        $expr = Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::BINARY,
            lhs => $expr,
            op => $op,
            rhs => $rhs,
        );
    }

    return $expr;
}

sub _parse_term($self) {
    my $expr = $self->_parse_factor();

    while (my $op = $self->_match(TokenType::MINUS, TokenType::PLUS)) {
        my $rhs = $self->_parse_factor();
        $expr = Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::BINARY,
            lhs => $expr,
            op => $op,
            rhs => $rhs,
        );
    }

    return $expr;
}

sub _parse_factor($self) {
    my $expr = $self->_parse_unary();

    while (my $op = $self->_match(TokenType::SLASH, TokenType::STAR)) {
        my $rhs = $self->_parse_unary();
        $expr = Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::BINARY,
            lhs => $expr,
            op => $op,
            rhs => $rhs,
        );
    }

    return $expr;
}

sub _parse_unary($self) {
    if (my $op = $self->_match(TokenType::BANG, TokenType::MINUS)) {
        my $rhs = $self->_parse_unary();
        return Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::UNARY,
            op => $op,
            value => $rhs,
        );
    }

    return $self->_parse_primary();
}

sub _parse_primary($self) {
    # In Perl it's hard to distinguish numbers/booleans/strings
    # which are notably different in the Lox language
    if (my $boolean_token = $self->_match(TokenType::FALSE, TokenType::TRUE)) {
        return Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::LITERAL,
            value => $boolean_token,
        );
    } elsif (my $num_or_str_token = $self->_match(TokenType::NUMBER, TokenType::STRING)) {
        return Perlox::Interpreter::Parser::Expression->new(
            type => ExpressionType::LITERAL,
            value => $num_or_str_token,
        );
    } elsif ($self->_match(TokenType::LEFT_PAREN)) {
        my $expr = $self->_parse_expression();
        if ($self->_match(TokenType::RIGHT_PAREN)) {
            return Perlox::Interpreter::Parser::Expression->new(
                type => ExpressionType::GROUPING,
                inner_expr => $expr,
            );
        } else {
            # TODO show error
        }
    }
}

sub _get_current_token($self) {
    return $self->{tokens}[$self->{offset}];
}

sub _move_to_next_token($self) {
    return $self->{tokens}[$self->{offset}++];
}

sub _match($self, @token_types) {
    if (any { $self->_get_current_token()->{type} == $_ } @token_types) {
        return $self->_move_to_next_token();
    }
    return 0;
}

sub _is_eof($self) {
    return $self->{offset} >= scalar($self->{tokens}->@*);
}

1;