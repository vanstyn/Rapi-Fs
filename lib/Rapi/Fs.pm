package Rapi::Fs;
use Moose;
use namespace::autoclean;

use RapidApp 1.0000;

use Catalyst qw/
    -Debug
    RapidApp::RapidDbic
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'Rapi::Fs',

    # The general 'RapidApp' config controls aspects of the special components that
    # are globally injected/mounted into the Catalyst application dispatcher:
    'RapidApp' => {
      ## To change the root RapidApp module to be mounted someplace other than
      ## at the root (/) of the Catalyst app (default is '' which is the root)
      #module_root_namespace => 'adm',

      ## To load additional, custom RapidApp modules (under the root module):
      #load_modules => { somemodule => 'Some::RapidApp::Module::Class' }
    },

);

# Start the application
__PACKAGE__->setup();

1;

__END__

=head1 NAME

Rapi::Fs - Catalyst/RapidApp based application

=head1 SYNOPSIS

    script/rapi_fs_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<RapidApp>, L<Catalyst>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
