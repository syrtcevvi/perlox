package Perlox::Interpreter;

=encoding utf8
=head1 Brief description

    Tree-walking interpreter for the Lox language.

=cut

use v5.24;
use strict;
use warnings;
use utf8;
use experimental 'signatures';
use lib::abs '../';

use Syntax::Keyword::Match;
use Path::Class::File ();
use Term::ReadLine ();
use Readonly qw(Readonly);
use Try::Tiny qw(try catch);

use Perlox::Interpreter::Exceptions ();
use Perlox::Interpreter::Scanner ();
use Perlox::Interpreter::Parser ();
use Perlox::CLI qw(
    show_repl_header
    show_repl_exit_message
);

Readonly::Scalar our $VERSION => '0.1.0';

sub new($class, %args) {
    return bless(
        {
            options => {
                verbose => $args{verbose},
            },
            scanner => Perlox::Interpreter::Scanner->new(),
            parser => Perlox::Interpreter::Parser->new(),
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
    try {
        my $tokens = $self->{scanner}->get_tokens($source_string);

        # TODO CLI module
        if ($self->{options}{verbose}) {
            say('Scanner output:');
            foreach my $token (@$tokens) {
                say($token);
            }
            say('');
        }

        my $ast = $self->{parser}->parse($tokens);

        if ($self->{options}{verbose}) {
            say('Parser output:');
            say($ast);
        }

        # TODO tree-walking execution
    } catch {
        $self->_handle_exceptions($_);
        return;
    };
}

sub run_repl($self) {
    show_repl_header($VERSION);

    my $term = Term::ReadLine->new('perlox CLI interface');
    $term->enableUTF8();
    $term->ornaments('');

    my $line_i = 1;
    my $source_code_line = '';
    while (defined($source_code_line = $term->readline("$line_i: "))) {
        $self->run_from_string($source_code_line);

        $self->_reinit();
        $line_i++;
    }

    if (!defined($source_code_line)) {
        show_repl_exit_message();
        return;
    }
}

sub _reinit($self) {
    $self->{scanner}->init();
    $self->{parser}->init();
}

sub _handle_exceptions($self, $exception) {
    # TODO Reporter module or smth similar
    match ($exception : isa) {
        case (Perlox::Interpreter::Scanner::Exception) {
            foreach my $scanner_error ($_->errors->@*) {
                say(sprintf(
                    '%s, at line %d, column: %d',
                    @{$scanner_error}{qw(error line column)},
                ));
            }
        }
        case (Perlox::Interpreter::Parser::Exception) {
            foreach my $parser_error ($_->errors->@*) {
                # TODO
            }
        }
        default {
            say $_;
        }
    }
}

1;