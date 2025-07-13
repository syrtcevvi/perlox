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

use Perlox::Interpreter::Scanner ();

sub new($class, %args) {
    my $self = bless({}, $class);
    return $self->_init(verbose => $args{verbose});
}

sub parse($self, $source_code) {
    my $tokens = $self->{scanner}->get_tokens($source_code);
}

sub _init($self, %args) {
    %$self = (
        %$self,

        options => {
            verbose => $args{verbose},
        },

        scanner => Perlox::Interpreter::Scanner->new(verbose => $args{verbose}),
        ast => {},
    );
    return $self;
}

1;