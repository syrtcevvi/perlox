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

sub new($class, %args) {
    my $self = bless({
        options => {
            verbose => $args{verbose},
        },
    }, $class);
    return $self->init();
}

sub parse($self, $source_code) {
    $self->{tokens} = $self->{scanner}->get_tokens($source_code);
}

sub init($self) {
    %$self = (
        %$self,

        tokens => [],
    );
    return $self;
}

1;