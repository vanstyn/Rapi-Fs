package Rapi::Fs::Symlink;

use strict;
use warnings;

# ABSTRACT: Object representing a symlink

use Moo;
extends 'Rapi::Fs::File';
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

sub is_file  { 0 }
sub is_link  { 1 }

sub _has_attr {
  my $attr = shift;
  has $attr, is => 'rw', isa => Maybe[Str], lazy => 1,
  default => sub {
    my $self = shift;
    $self->driver->call_node_get( $attr => $self )
  }, @_
}

_has_attr 'link_target', is => 'ro', isa => Str;


1;
