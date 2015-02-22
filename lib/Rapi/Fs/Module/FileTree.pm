package Rapi::Fs::Module::FileTree;

use strict;
use warnings;

# ABSTRACT: ExtJS tree for Rapi::Fs::Driver filesystems

use Moo;
extends 'RapidApp::Module::Tree';
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

## ----
## Our own, modified base64 encode/decode using '-' instead of '/'
#use MIME::Base64;
#
#sub b64_encode {
#  my $str = MIME::Base64::encode($_[0]);
#  $str =~ s/\//\-/g;
#  $str =~ s/\r?\n//g;
#  $str
#}
#
#sub b64_decode {
#  my $str = shift;
#  $str =~ s/\-/\//g;
#  MIME::Base64::decode($str)
#}
## ----

# ^^ Special base64 encoding not really needed at this point, 
#    turn off w/ raw passthrough:
sub b64_encode { (shift) }
sub b64_decode { (shift) }


has 'mounts', is => 'ro', isa => ArrayRef[InstanceOf['Rapi::Fs::Driver']], required => 1;

has 'mounts_ndx', is => 'ro', lazy => 1, init_arg => undef, default => sub {
  my $self = shift;
  return { map { $_->name => $_ } @{$self->mounts} }
}, isa => HashRef;

sub BUILD {
  my $self = shift;
  
  my @mounts = @{ $self->mounts };
  die "Must supply at least one Rapi::Fs::Driver mount in mounts!" if (@mounts == 0);
  
  my %seen = ();
  $seen{$_->name}++ and die join(' ',"Duplicate mount name",$_->name) for (@mounts);
  
  $self->mounts_ndx; #init
}


sub fetch_nodes {
  my ($self, $node) = @_;
  
  return $self->mounts_nodes if ($node eq 'root');
  
  my ($prefix, $enc_path) = split(/\//,$node,2);
  die "Malformed node path '$node'" unless ($prefix eq 'root');
  
  my ($mount, $path) = split(/\//,&b64_decode($enc_path),2);
  
  my $Mount = $self->mounts_ndx->{$mount} or die "No such mount '$mount'";
  
  return [ map {{
    id       => join('/','root',&b64_encode(join('/',$mount,$_->path))),
    name     => $_->name,
    text     => $_->name,
    leaf     => $_->is_dir ? 0 : 1,
    loaded   => $_->is_dir ? 0 : 1,
    expanded => $_->is_dir ? 0 : 1,
  }} $Mount->get_subnodes($path || '/') ];
}



sub mounts_nodes {
  my $self = shift;

  return [ map {{
    id       => join('/','root',&b64_encode($_->name)),
    name     => $_->name,
    text     => $_->name,
    expanded => 0
  
  }} @{$self->mounts} ]
}


1;
