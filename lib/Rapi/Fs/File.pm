package Rapi::Fs::File;

use strict;
use warnings;

# ABSTRACT: Object representing a file

use Moo;
extends 'Rapi::Fs::Node';
use Types::Standard qw(:all);
use Number::Bytes::Human qw(format_bytes parse_bytes);

sub _has_attr {
  my $attr = shift;
  has $attr, is => 'rw', isa => Maybe[Str], lazy => 1,
  default => sub {
    my $self = shift;
    $self->driver->call_node_get( $attr => $self )
  }, @_
}

_has_attr 'bytes', is => 'ro', isa => Int;

sub bytes_human { format_bytes( (shift)->bytes ) }


# These are extra, *optional* attrs which might be available in driver and/or set by user:
_has_attr $_ for qw(
  download_url
  mime_type
  mime_subtype
  height
  width
);


1;
