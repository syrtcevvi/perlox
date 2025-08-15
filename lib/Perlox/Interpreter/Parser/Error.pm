package Perlox::Interpreter::Parser::Error;

=encoding utf8
=head1 Brief description

    Represents an error that occurs on the parsing stage.

=cut

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;
use lib::abs '../../../';

use Moose;
use MooseX::StrictConstructor;

use overload
    '""' => \&_to_string;


sub _to_string {
    my ($self) = @_;
    # TODO
    return 'TODO'
}

1;