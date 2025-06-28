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
use Try::Tiny qw(try catch);

use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Scanner ();
use Perlox::CLI qw(
    show_repl_header
    show_repl_exit_message
    show_prompt
);

Readonly::Scalar our $VERSION => '0.1.0';

sub new($class) {
    return bless(
        {
            scanner => Perlox::Interpreter::Scanner->new(),
        },
        $class,
    );
}

sub run_from_file($self, $path_to_script) {
    my $script_content;
    try {
        $script_content = Path::Class::File->new($path_to_script)->slurp();
    } catch {
        # Use $! instead of $_ for the sake of brevity,
        # $_ additionally includes the line number in a script
        Perlox::Interpreter::FileReadException->throw(
            error => sprintf(
                'Unable to open file "%s" for reading: %s',
                $path_to_script, $!
            ),
            path_to_file => $path_to_script,
        );
    };
     
    $self->run_from_string($script_content);
}

sub run_from_string($self, $source_string) {
    my $tokens = $self->{scanner}->get_tokens($source_string);

    use Data::Dumper;
    print Dumper $tokens;
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
        $self->run_from_string($source_code_line);
    }
}

1;