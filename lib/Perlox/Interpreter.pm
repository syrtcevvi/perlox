package Perlox::Interpreter;

=encoding utf8
=head1 Brief description

TODO

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental 'signatures';
use lib::abs '../';

use Syntax::Keyword::Match;
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
        die(sprintf(
            'Unable to open file "%s" for reading: %s' . "\n",
            $path_to_script, $!
        ));
    };

    $self->run_from_string($script_content);
}

sub run_from_string($self, $source_string) {
    my $tokens;
    try {
        $tokens = $self->{scanner}->get_tokens($source_string);
        # TODO parser, tree-walking execution
    } catch {
        $self->_handle_exceptions($_);
        return;
    };

    foreach my $token (@$tokens) {
        print $token, "\n";
    }
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

        # Clear the interpreter scanner state
        $self->_reinit_scanner();
    }
}

sub _reinit($self) {
    # TODO
}

sub _reinit_scanner($self) {
    $self->{scanner} = Perlox::Interpreter::Scanner->new();
}

sub _handle_exceptions($self, $exception) {
    # TODO Reporter module or smth similar
    match ($exception : isa) {
        case (Perlox::Interpreter::Scanner::Exception) {
            foreach my $unexpected_character_error ($_->errors->@*) {
                say(sprintf(
                    '%s, at line %d, column: %d',
                    @{$unexpected_character_error}{qw(error line column)},
                ));
            }
        }
        default {
            say $_;
        }
    }
}

1;