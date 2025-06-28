package Perlox::Interpreter::Token;

=encoding utf8
=head1 Brief description

TODO

=cut

use v5.24;
use strict;
use warnings;
use experimental 'signatures';

use overload
    '""' => \&_to_string;

sub new($class, %args) {
    return bless({
        token_type => $args{token_type},
        span => $args{span},
        line => $args{line},
    }, $class);
}

sub _to_string {
    my ($self) = @_;
    return $self->{lexeme};
}

1;