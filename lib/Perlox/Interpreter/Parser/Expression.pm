package Perlox::Interpreter::Parser::Expression;

=encoding utf8
=head1 Brief description

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);
use lib::abs '../../../';

use Syntax::Keyword::Match;
use Readonly qw(Readonly);

Readonly::Scalar my $OFFSET_INC => 1;
Readonly::Scalar my $INDENTATION_SEQUENCE => '| ';

use overload
    '""' => \&_to_string;

BEGIN {
    use Perlox::Interpreter::Parser::Expression::Type ();
    *ExpressionType:: = *Perlox::Interpreter::Parser::Expression::Type::;
};

sub new($class, %args) {
    return bless({%args}, $class);
}

sub _to_string {
    my ($self) = @_;

    return $self->_get_expression_tree(0);
}

sub _get_expression_tree($self, $offset) {
    match($self->{type} : ==) {
        case (ExpressionType::LITERAL) {
            return($INDENTATION_SEQUENCE x $offset . $self->{value} . "\n");
        } case (ExpressionType::UNARY) {
            return ($INDENTATION_SEQUENCE x $offset . $self->{op} . "\n")
                . $self->{value}->_get_expression_tree($offset + $OFFSET_INC);
        } case (ExpressionType::BINARY) {
            return($INDENTATION_SEQUENCE x $offset . $self->{op} . "\n")
                . $self->{lhs}->_get_expression_tree($offset + $OFFSET_INC)
                . $self->{rhs}->_get_expression_tree($offset + $OFFSET_INC);
        } case (ExpressionType::GROUPING) {
            return $self->{inner_expr}->_get_expression_tree($offset + $OFFSET_INC);
        }
    }
}

1;