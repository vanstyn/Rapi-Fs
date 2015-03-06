use strict;
use warnings;

use Rapi::Fs;
use Rapi::Fs::Driver::Filesystem;

# -----------------
# Temporary/just for development -- will be replaced with a real system for
# configuring and loading mounts later on ....
my $mounts = [
  Rapi::Fs::Driver::Filesystem->new({
    name => 'root-home',
    args => '/root'
  }),
  Rapi::Fs::Driver::Filesystem->new({
    name => 'usr-lib-perl5',
    args => '/usr/lib/perl5'
  })
];
sub _get_driver_mounts { $mounts }
#
# -----------------

Rapi::Fs->new({
  debug   => 1,
  appname => 'Testing::Rapi::Fs',
  mounts  => $mounts
})->to_app

