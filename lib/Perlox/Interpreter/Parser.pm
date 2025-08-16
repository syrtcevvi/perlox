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
use experimental 'signatures';
use lib::abs '../../';

use Clone qw(clone);
use Carp qw(confess);
use List::Util qw(any);

BEGIN {
    use Perlox::Interpreter::Types::Token::Type ();
    # Allows us to save some typing when working with token types
    *TokenType:: = *Perlox::Interpreter::Types::Token::Type::;
    use Perlox::Interpreter::Parser::Error::Type ();
    *ErrorType:: = *Perlox::Interpreter::Parser::Error::Type::;
};
use Perlox::Interpreter::Parser::Error ();
use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Types::Expression::Literal ();
use Perlox::Interpreter::Types::Expression::Literal::Boolean ();
use Perlox::Interpreter::Types::Expression::Literal::Number ();
use Perlox::Interpreter::Types::Expression::Literal::String ();
use Perlox::Interpreter::Types::Expression::Grouping ();
use Perlox::Interpreter::Types::Expression::Unary ();
use Perlox::Interpreter::Types::Expression::Binary ();

use Class::Tiny {
    _tokens => [],
    _offset => 0,
    _last_token => undef,
    _errors => [],
};

sub init($self) {
    $self->_tokens([]);
    $self->_offset(0);
    $self->_last_token(undef);
    $self->_errors([]);
}

sub parse($self, $tokens) {
    $self->_tokens($tokens);

    my $expr = $self->_parse_expression();

    if (scalar($self->_errors->@*)) {
        Perlox::Interpreter::Parser::Exception->throw(
            errors => $self->_errors,
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
        $expr = Perlox::Interpreter::Types::Expression::Binary->new(
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
        $expr = Perlox::Interpreter::Types::Expression::Binary->new(
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
        $expr = Perlox::Interpreter::Types::Expression::Binary->new(
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
        $expr = Perlox::Interpreter::Types::Expression::Binary->new(
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
        return Perlox::Interpreter::Types::Expression::Unary->new(
            op => $op,
            value => $rhs,
        );
    }

    return $self->_parse_primary();
}

sub _parse_primary($self) {
    if (my $boolean_token = $self->_match(TokenType::FALSE, TokenType::TRUE)) {
        return Perlox::Interpreter::Types::Expression::Literal::Boolean->new(
            value => $boolean_token,
        );
    } elsif (my $number_token = $self->_match(TokenType::NUMBER)) {
        return Perlox::Interpreter::Types::Expression::Literal::Number->new(
            value => $number_token,
        );
    } elsif (my $string_token = $self->_match(TokenType::STRING)) {
        return Perlox::Interpreter::Types::Expression::Literal::String->new(
            value => $string_token,
        );
    } elsif ($self->_match(TokenType::LEFT_PAREN)) {
        my $expr = $self->_parse_expression();
        if ($self->_match(TokenType::RIGHT_PAREN)) {
            return Perlox::Interpreter::Types::Expression::Grouping->new(
                value => $expr,
            );
        } else {
            $self->_save_error(
                type => ErrorType::MISSED_CLOSING_PAREN,
                message => 'Missed closing paren',
            );
        }
    }
    # TODO error
}

sub _get_current_token($self) {
    my $current_token = $self->_tokens->[$self->_offset];

    if (defined($current_token)) {
        $self->_last_token($current_token);
    }
    return $current_token;
}

sub _move_to_next_token($self) {
    my $current_token = $self->_tokens->[$self->_offset];
    $self->_offset($self->_offset + 1);
    return $current_token;
}

sub _match($self, @token_types) {
    my $current_token = $self->_get_current_token();

    if (defined($current_token) && any { $current_token->type == $_ } @token_types) {
        return $self->_move_to_next_token();
    }

    return;
}

sub _is_eof($self) {
    return $self->_offset >= scalar($self->_tokens->@*);
}

sub _save_error($self, %args) {
    if (!defined($self->_last_token)) {
        confess('$self->_last_token is undef, it must contain the last token, exit');
    }

    push(
        $self->_errors->@*,
        Perlox::Interpreter::Parser::Error->new(
            type => $args{type},
            message => $args{message},
            last_token_span => clone($self->_last_token->span),
            line => $self->_last_token->line,
        ),
    );
    $self->_last_token(undef);
}

1;