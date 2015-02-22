package Rapi::Fs::Driver::Filesystem;

use strict;
use warnings;

# ABSTRACT: Standard filesystem driver

use Moo;
extends 'Rapi::Fs::Driver';
use Types::Standard qw(:all);

use Path::Class qw( file dir );

use Rapi::Fs::File;
use Rapi::Fs::Dir;

has 'top_dir', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  die "args must contain a valid directory path" unless ($self->args);
  
  my $dir = dir( $self->args )->resolve;
  die "$dir is not a directory!" unless (-d $dir);

}, isa => InstanceOf['Path::Class::Dir'];


sub BUILD {
  my $self = shift;
  $self->top_dir; # init
}



sub get_node {
  my ($self, $path) = @_;
  
  my $Ent = $self->_path_obj($path) or return undef;
  $self->_node_factory($Ent)
}


sub get_subnodes {
  my ($self, $path) = @_;
  
  my $Ent = $self->_path_obj($path); 

  $Ent && $Ent->is_dir 
    ? [ map { $self->_node_factory($_) } $Ent->children ]
    : []
}



# Returns a Path::Class::Dir, Path::Class::File or undef
sub _path_obj {
  my ($self, $path) = @_;
  
  defined $path return undef;
  
  return $self->top_dir if ($path eq '/' || $path eq '');

  my $Ent = $self->top_dir->subdir( $path );
  
  -d $Ent ? $Ent :
  -e $Ent ? $self->top_dir->file($path) : undef
}

sub _node_factory {
  my ($self, $Ent) = @_;
  
  my $class = $Ent->is_dir ? 'Rapi::Fs::Dir' : 'Rapi::Fs::File';
  
  $class->new({
    name   => $Ent->basename,
    path   => $path,
    driver => $self
  })
}


1;
