package Rapi::Fs;

use strict;
use warnings;

use RapidApp 1.0010_06;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use FindBin;

our $VERSION = '0.01';

has 'mounts', is => 'ro', isa => ArrayRef, required => 1;

has 'share_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  try{dist_dir(ref $self)} || "$FindBin::Bin/share";
};

sub _build_version { $VERSION }
sub _build_plugins { ['RapidApp::TabGui'] }

sub _build_config {
  my $self = shift;
  
  return {
    'RapidApp' => {
      load_modules => {
        files => {
          class  => 'Rapi::Fs::Module::FileTree',
          params => { mounts => $self->mounts }
        }
      }
    },
    'Plugin::RapidApp::TabGui' => {
      navtrees => [{
        module => '/files',
      }]  
    },
    'Controller::RapidApp::Template' => {
      include_paths => [ join('/',$self->share_dir,'templates') ]
    },
  }
}

1;
