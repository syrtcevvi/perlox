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
        description => 'Exception class for scanner-related errors',
        fields => ['errors'],
    },
    Perlox::Interpreter::Parser::Exception => {
        isa => 'Perlox::Interpreter::Exception',
        description => 'Exception class for parser-related errors',
        fields => ['errors'],
    },
);

1;