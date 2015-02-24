package Rapi::Fs::Node;

use strict;
use warnings;

# ABSTRACT Base class for Dir and File objects

use Moo;
use Types::Standard qw(:all);

has 'driver', is => 'ro', isa => InstanceOf['Rapi::Fs::Driver'], required => 1;
has 'path',   is => 'ro', isa => Str, required => 1;
has 'name',   is => 'ro', isa => Str, required => 1;

sub is_dir   { 0 }
sub subnodes { [] }

# Arbitrary container reserved for the driver to persist/cache data associated
# with this node object. What this will hold, if anything, is up to the driver
# and is intended for internal use by the driver only
has 'driver_stash', is => 'ro', isa => HashRef, default => sub {{}};

sub _has_attr {
  my $attr = shift;
  has $attr, is => 'rw', isa => Maybe[Str], lazy => 1,
  default => sub {
    my $self = shift;
    $self->driver->call_node_get( $attr => $self )
  }, @_
}

_has_attr 'mtime',       is => 'ro', isa => Int;
_has_attr 'parent_path', is => 'ro', isa => Maybe[Str];
_has_attr 'parent',      is => 'ro', isa => Maybe[InstanceOf['Rapi::Fs::Dir']];


# These are extra, *optional* attrs which might be available in driver and/or set by user:
_has_attr $_ for qw(
  iconCls
  cls
  view_url
);









1;
