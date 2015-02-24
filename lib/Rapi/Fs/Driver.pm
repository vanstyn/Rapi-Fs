package Rapi::Fs::Driver;

use strict;
use warnings;

# ABSTRACT Base class for all Drivers

use Moo;
use Types::Standard qw(:all);

has 'name', is => 'ro', isa => Str, required => 1;
has 'args', is => 'ro', isa => Maybe[Str], default => sub { undef };


sub call_node_get {
  my ($self, $attr, @args) = @_;
  my $meth = "node_get_$attr";
  $self->can($meth) ? $self->$meth(@args) : undef
}

=head2 get_node

Must be defined in subclass - accepts a path string and returns the associated Node object. 
Must also be able accept existing Node object arg and return it back to the caller as-is.
=cut
sub get_node { ... }

# Required node_get_ methods:
sub node_get_parent { ... }
sub node_get_parent_path { ... }
sub node_get_subnodes { ... }
sub node_get_bytes { ... }
sub node_get_mtime { ... }


1;
