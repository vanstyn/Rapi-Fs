package Rapi::Fs::Role::Driver;

use strict;
use warnings;

# ABSTRACT Base role for all driver classes

use Moo::Role;
use Types::Standard qw(:all);

has 'name', is => 'ro', isa => Str, lazy => 1, required => 1;
has 'args', is => 'ro', isa => Maybe[Str], default => sub { undef };

=head2 get_node

Must be defined in subclass - accepts a path string and returns the associated Node object. 
Must also be able accept existing Node object arg and return it back to the caller as-is.
=cut

requires 'get_node';

# Required node_get_ methods:
requires 'node_get_parent';
requires 'node_get_parent_path';
requires 'node_get_subnodes';
requires 'node_get_bytes';
requires 'node_get_mtime';
requires 'node_get_fh';
requires 'node_get_mimetype';
requires 'node_get_link_target';

# Note that other node_get_* methods may be implemented, but are not required.

sub call_node_get {
  my ($self, $attr, @args) = @_;
  my $meth = "node_get_$attr";
  $self->can($meth) ? $self->$meth(@args) : undef
}



1;
