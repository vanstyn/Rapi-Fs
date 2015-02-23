package Rapi::Fs::Node;

use strict;
use warnings;

# ABSTRACT Base class for Dir and File objects

use Moo;
use Types::Standard qw(:all);

has 'driver', is => 'ro', isa => InstanceOf['Rapi::Fs::Driver'], required => 1;
has 'path',   is => 'ro', isa => Str, required => 1;
has 'name',   is => 'ro', isa => Str, required => 1;

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


sub parent {
  my $self = shift;
  $self->parent_path 
    ? $self->driver->get_node( $self->parent_path ) 
    : undef
}

sub is_dir { 0 }
sub subnodes { [] }

1;
