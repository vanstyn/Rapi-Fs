package Rapi::Fs::File;

use strict;
use warnings;

# ABSTRACT: Object representing a file

use Moo;
extends 'Rapi::Fs::Node';
use Types::Standard qw(:all);
use Number::Bytes::Human qw(format_bytes parse_bytes);

use RapidApp::Util qw(:all);

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

sub bytes_human { 
  my $str = format_bytes( (shift)->bytes );
  $str .= 'B' if ($str =~ /^\d+$/); # Always show unit, even when <1K
  $str
}

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
  
  # Default, generic text and binary types:
  unless ($top && $sub) {
    ($top,$sub) = $self->is_text 
      ? (qw/text plain/)      
      : (qw/application octet-stream/) 
  }

  my $ct = join('/',$top,$sub);

  $ct = join('',$ct,'; charset=',$self->text_encoding) if (
       $self->is_text
    && $self->text_encoding
  );

  $ct
}, isa => Str;

has 'file_ext', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return undef unless ($self->name);
  my @parts = split(/\./,$self->name);
  return undef unless (scalar @parts > 1);
  return lc(pop @parts);
}, isa => Maybe[Str];


# These are extra, *optional* attrs which might be available in driver and/or set by user:
_has_attr $_ for qw(
  download_url
  open_url
  is_text
  text_encoding
);


1;
