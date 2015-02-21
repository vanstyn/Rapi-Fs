package Rapi::Fs::Driver::Filesystem;

use strict;
use warnings;

# ABSTRACT: Standard filesystem driver

use Moo;
extends 'Rapi::Fs::Driver';
use Types::Standard qw(:all);

use Path::Class qw( file dir );

has 'top_dir', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  die "args must contain a valid directory path" unless ($self->args);
  
  my $dir = dir( $self->args )->resolve;
  die "$dir is not a directory!" unless (-d $dir);

}, isa => InstanceOf['Path::Class::Dir'];






1;
