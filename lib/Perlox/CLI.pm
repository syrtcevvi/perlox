package Perlox::CLI;

=encoding utf8
=head1 Brief description

TODO

=cut

use v5.24;
use strict;
use warnings;
use experimental 'signatures';

use Exporter 'import';
use Term::ANSIColor qw(color);

our @EXPORT_OK = qw(
    show_help_message
    show_file_opening_error
    show_repl_header
    show_repl_exit_message
    show_prompt
);

sub show_help_message() {
    print(color('bold blue'));
    say('Usage: perlox [script]');
    print(color('reset'));
    return;
}

sub show_file_opening_error($file_name, $error_message) {
    print(color('bold red'));
    print("Error opening the file '$file_name': ");
    print(color('reset'));
    say($error_message);
    print(color('reset'));
    return;
}

sub show_repl_header($version) {
    print(color('bold green'));
    say("Perlox $version REPL");
    print(color('reset'));
    return;
}

sub show_repl_exit_message() {
    say("\nBye-bye");
    return;
}

sub show_prompt() {
    print('> ');
    return;
}

1;