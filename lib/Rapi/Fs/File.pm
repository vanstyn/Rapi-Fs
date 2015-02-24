package Rapi::Fs::File;

use strict;
use warnings;

# ABSTRACT: Object representing a file

use Moo;
extends 'Rapi::Fs::Node';
use Types::Standard qw(:all);

has 'bytes', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->driver->get_file_bytes( $self )
}, isa => Int;


1;
