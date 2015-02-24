package Rapi::Fs::Module::Role::Mounts;

use strict;
use warnings;

# ABSTRACT: Role for modules which use "Mounts"

use Moo::Role;
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

# From RapidApp::Module
has 'accept_subargs',   is => 'rw', isa => Bool, default => sub {1};

has 'mounts', is => 'ro', isa => ArrayRef[InstanceOf['Rapi::Fs::Driver']], required => 1;

has '_mounts_ndx', is => 'ro', lazy => 1, init_arg => undef, default => sub {
  my $self = shift;
  return { map { $_->name => $_ } @{$self->mounts} }
}, isa => HashRef;


sub get_mount {
  my ($self, $mount) = @_;
  $self->_mounts_ndx->{$mount} or die "No such mount '$mount'";
}

sub BUILD {}
after 'BUILD' => sub {
  my $self = shift;
  
  my @mounts = @{ $self->mounts };
  die "Must supply at least one Rapi::Fs::Driver mount in mounts!" if (@mounts == 0);
  
  my %seen = ();
  $seen{$_->name}++ and die join(' ',"Duplicate mount name",$_->name) for (@mounts);
  
  $self->_mounts_ndx; #init
};


## ----
## Our own, modified base64 encode/decode using '-' instead of '/'
#use MIME::Base64;
#
#sub b64_encode {
#  my $self = shift;
#  my $str = MIME::Base64::encode($_[0]);
#  $str =~ s/\//\-/g;
#  $str =~ s/\r?\n//g;
#  $str
#}
#
#sub b64_decode {
#  my $self = shift;
#  my $str = shift;
#  $str =~ s/\-/\//g;
#  MIME::Base64::decode($str)
#}
## ----

# ^^ Special base64 encoding not really needed at this point, 
#    turn off w/ raw passthrough:
sub b64_encode { $_[1] }
sub b64_decode { $_[1] }

sub Node_from_local_args {
  my $self = shift;
  
  my @largs = $self->local_args;
  return undef unless (@largs > 0);
  
  my $mount = shift @largs;
  my $path  = scalar(@largs > 0) ? $self->b64_decode( join('/',@largs) ) : '/';
  
  my $Mount = try{ $self->get_mount($mount) } or die usererr "No such mount '$mount'";
  
  $Mount->get_node($path);
}


1;
