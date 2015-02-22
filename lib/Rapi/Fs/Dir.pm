package Rapi::Fs::Dir;

use strict;
use warnings;

# ABSTRACT: Object representing a directory

use Moo;
extends 'Rapi::Fs::Node';
use Types::Standard qw(:all);

sub is_dir { 1 }

sub subnodes {
  my $self = shift;
  $self->driver->get_subnodes( $self->path )
}



1;
