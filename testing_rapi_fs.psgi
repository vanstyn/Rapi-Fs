use strict;
use warnings;

use Rapi::Fs;

# -----------------
# Example mounts:
my $mounts = [
  {
    driver => 'Filesystem',
    name   => 'root-home',
    args   => '/root'
  },
  {
    driver => 'Filesystem',
    name   => 'usr-lib-perl5',
    args   => '/usr/lib/perl5'
  }
];
#
# -----------------

Rapi::Fs->new({
  debug   => 1,
  appname => 'Testing::Rapi::Fs',
  mounts  => $mounts
})->to_app

