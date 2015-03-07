use strict;
use warnings;

use Rapi::Fs;

# -----------------
# Example mounts:
my $mounts = [
  {
    driver => 'Filesystem',
    args   => '/root'
  },
  {
    driver => 'Filesystem',
    name   => 'usr-lib-perl5',
    args   => '/usr/lib/perl5'
  },
  {
    name => 'something',
    args => '/usr/local/bin'
  },
  '/etc/conf.d',
  'Fooblag:Filesystem:/mnt',
  ':+Rapi::Fs::Driver::Filesystem:/opt/site/',
  'vanstyn-home:/home/vanstyn',
  '/etc',
  '/home'
];
#
# -----------------

Rapi::Fs->new({
  debug   => 1,
  appname => 'Testing::Rapi::Fs',
  mounts  => $mounts
})->to_app

