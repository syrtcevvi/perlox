package Perlox::CLI;

=encoding utf8
=head1 Brief description

    Some IO specific functions which are usable mainly in the REPL mode.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental 'signatures';

use Exporter 'import';
use Term::ANSIColor qw(color);

our @EXPORT_OK = qw(
    show_file_opening_error
    show_version
    show_repl_header
    show_repl_exit_message

    show_scanner_debug_output
    show_parser_debug_output

    show_error
);

sub show_file_opening_error($file_name, $error_message) {
    print(color('bold red'));
    print("Error opening the file '$file_name': ");
    print(color('reset'));
    say($error_message);
    print(color('reset'));
    return;
}

sub show_version($version) {
    say("Perlox $version");
    return;
}

sub show_repl_header($version) {
    print(color('bold green'));
    print("Perlox $version REPL");
    print(color('reset'));
    print("\n");
    return;
}

sub show_repl_exit_message() {
    say("\nBye-bye");
    return;
}

sub show_scanner_debug_output($tokens) {
    print(color('bright_black'));
    say("\nScanner output:");
    foreach my $token (@$tokens) {
        say($token);
    }
    print(color('reset'));
    return;
}

sub show_parser_debug_output($ast) {
    print(color('bright_black'));
    say("\nParser output:\n$ast");
    print(color('reset'));
    return;
}

sub show_error($error) {
    print(color('red'));
    say($error);
    print(color('reset'));
    return;
}

1;