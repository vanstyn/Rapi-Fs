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

_has_attr 'fh',       is => 'ro', isa => InstanceOf['IO::Handle'];
_has_attr 'bytes',    is => 'ro', isa => Int;
_has_attr 'mimetype', is => 'ro', isa => Maybe[Str];

sub bytes_human { format_bytes( (shift)->bytes ) }

has 'mime_type', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $mt = $self->mimetype or return undef;
  (split(/\//,$mt))[0]
}, isa => Maybe[Str];

has 'mime_subtype', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $mt = $self->mimetype or return undef;
  (split(/\//,$mt))[1]
}, isa => Maybe[Str];

has 'content_type', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my ($top,$sub) = ($self->mime_type,$self->mime_subtype);
  
  # Default, generic type:
  ($top,$sub) = (qw/application octet-stream/) unless ($top && $sub);
  
  my $ct = join('/',$top,$sub);
  
  # TODO: get real encoding
  $ct = join('; ',$ct,'charset=utf-8') if ($top eq 'text');
  
  $ct
}, isa => Str;


# These are extra, *optional* attrs which might be available in driver and/or set by user:
_has_attr $_ for qw(
  download_url
);


1;
