package Perlox::Interpreter::Exceptions;

=encoding utf8
=head1 Brief description

    Provides typed exceptions for the Perlox interpreter internal usage.

=cut

use Exception::Class (
    Perlox::Interpreter::Exception => {
        description => 'base exception class for interpreter-related exceptions'
    },

    Perlox::Interpreter::Scanner::Exception => {
        isa => 'Perlox::Interpreter::Exception',
        description => 'base exception class for scanner-related exceptions',
    },
    Perlox::Interpreter::Scanner::UnexpectedCharacterException => {
        isa => 'Perlox::Interpreter::Scanner::Exception',
        description => 'Scanner faced an unknown character',
        fields => ['errors'],
    },
);

1;