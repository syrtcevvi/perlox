package Perlox::Interpreter::Scanner::Utils;

=encoding utf8
=head1 Brief description

    Some tiny utility Scanner functions.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental 'signatures';

use Exporter qw(import);
use List::Util qw(any);

our @EXPORT_OK = qw(
    is_digit
    is_whitespace
);

sub is_digit($maybe_digit) {
    return $maybe_digit =~ m/^\d$/;
}

sub is_whitespace($maybe_whitespace) {
    $maybe_whitespace //= '';
    return any {
        $maybe_whitespace eq $_
    } (' ', "\r", "\t", "\f");
}

1;