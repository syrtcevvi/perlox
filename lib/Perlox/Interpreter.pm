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

    show_scanner_debug_output
    show_parser_debug_output

    show_error
);

use Class::Tiny {
    verbose => 0,
    _scanner => Perlox::Interpreter::Scanner->new(),
    _parser => Perlox::Interpreter::Parser->new(),
};

Readonly::Scalar our $VERSION => '0.1.0';

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

sub run_from_string($self, $source_code) {
    try {
        # Make iterator interface for the scanner?
        my $tokens = $self->_scanner->get_tokens($source_code);
        if ($self->verbose()) {
            show_scanner_debug_output($tokens);
        }

        my $ast = $self->_parser->parse($tokens);
        if ($self->verbose()) {
            show_parser_debug_output($ast);
        }

        # TODO tree-walking execution
    } catch {
        $self->_handle_exceptions($_);
        return;
    };
}

=head2 $self->run_repl()

    For the sake of brevity the Perlox::Interpreter contains this function, it helps check things interactively
    during the development and experiments.

    Maybe this function has to be defined in different place, because interpreter by itself
    has nothing to do with console IO (it just process the given input source) and can be embedded into application,
    for instance (where console IO is excess).

=cut
sub run_repl($self) {
    show_repl_header($VERSION);

    my $term = Term::ReadLine->new('Perlox REPL');
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
    $self->_scanner->init();
    $self->_parser->init();
}

sub _handle_exceptions($self, $exception) {
    # TODO Reporter module or smth similar
    match ($exception : isa) {
        case (Perlox::Interpreter::Scanner::Exception) {
            foreach my $scanner_error ($_->errors->@*) {
                show_error($scanner_error);
            }
        } case (Perlox::Interpreter::Parser::Exception) {
            foreach my $parser_error ($_->errors->@*) {
                show_error($parser_error);
            }
        } default {
            show_error($_);
        }
    }
}

1;