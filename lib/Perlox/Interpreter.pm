package Perlox::Interpreter;

=encoding utf8
=head1 Brief description

TODO

=cut

use v5.24;
use strict;
use warnings;
use experimental 'signatures';
use lib::abs '../';

use Path::Class::File ();
use Readonly qw(Readonly);

use Perlox::CLI qw(
    show_repl_header
    show_repl_exit_message
    show_prompt
);

Readonly::Scalar our $VERSION => '0.1.0';

sub new($class) {
    return bless(
        {},
        $class,
    );
}

sub run_from_file($self, $path_to_script) {
    my $script_content = Path::Class::File->new($path_to_script)->slurp();
    # TODO
}

sub run_repl($self) {
    show_repl_header($VERSION);

    my $source_code_line = '';
    while (1) {
        show_prompt();
        $source_code_line = <>;
        if (!defined($source_code_line)) {
            show_repl_exit_message();
            return;
        }
        # TODO eval and print the result
    }
}

1;