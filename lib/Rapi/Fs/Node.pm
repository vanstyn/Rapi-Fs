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

sub parent {
  my $self = shift;
  $self->parent_path ? $self->driver->get_node( $self->parent_path ) : undef
}

has 'parent_path', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  return undef unless (
    $self->path &&
    $self->path ne '' &&
    $self->path ne '/'
  );
  
  return '/' unless ($self->path =~ /\//);
  
  my @parts = split(/\//,$self->path);
  
  pop @parts if (pop @parts eq ''); # handles trailing '/'
  
  my $parent = scalar(@parts) > 0 ? join('/',@parts) : undef;
  $parent && $parent ne '' ? $parent : undef

}, isa => Maybe[Str], init_arg => undef;



sub _has_attr {
  my $attr = shift;
  has $attr, is => 'rw', isa => Maybe[Str], lazy => 1,
  default => sub {
    my $self = shift;
    $self->driver->call_node_get( $attr => $self )
  }, @_
}

_has_attr 'mtime', is => 'ro', isa => Int;


# These are extra, *optional* attrs which might be set by driver and/or user:
_has_attr $_ for qw(
  iconCls
  cls
  view_url
);









1;
