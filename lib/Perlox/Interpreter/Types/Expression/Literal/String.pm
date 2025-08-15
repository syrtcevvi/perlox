package Perlox::Interpreter::Types::Expression::Literal::String;

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;

use Moose;
extends 'Perlox::Interpreter::Types::Expression::Literal';

__PACKAGE__->meta->make_immutable;

1;