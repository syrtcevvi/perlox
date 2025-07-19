package Perlox::Interpreter::Error;

use v5.24;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);
use lib::abs '../../';

BEGIN {
    use Perlox::Interpreter::Error::Type ();
    *TokenType:: = *Perlox::Interpreter::Error::Type::;
};

use overload
    '""' => \&_to_string;

sub new($class, %args) {
    return bless({%args}, $class);
}

sub _to_string {
    my ($self) = @_;

    if ($self->{stage} eq 'scanner') {
        return sprintf(
            '%s, at line %d, column: %d',
            $self->{message}, $self->{location}{line},
            $self->{location}{span}{start},
        );
    } elsif ($self->{stage} eq 'parser') {
        # TODO
    }

    return '';
}

1;