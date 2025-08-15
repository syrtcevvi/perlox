package Perlox::Interpreter::Types::NonNegativeInt;

use v5.24;
use strictures 2;
use utf8;
use namespace::autoclean;

use Moose::Util::TypeConstraints;
use Types::Standard qw(Int);

subtype 'Perlox::Interpreter::Types::NonNegativeInt'
    => as Int
    => where { $_ >= 0 }
    => message { 'Integer must be >= 0' };

1;