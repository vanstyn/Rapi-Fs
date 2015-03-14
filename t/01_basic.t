# -*- perl -*-

use strict;
use warnings;

use Test::More;

BEGIN {
  use FindBin '$Bin';
  use Rapi::Fs;
  
  Rapi::Fs->new({
    appname => 'TestRA::RapiFs',
    mounts  => [{ 
      name => 'Rapi-Fs-Dist',
      args => "$Bin/../" 
    }]
  })->ensure_bootstrapped 
}

use RapidApp::Test 'TestRA::RapiFs';

run_common_tests();

my $dir = 'lib/Rapi/Fs';
my @real = map {
  (reverse split(/\//,$_))[0]
} glob("$Bin/../$dir/*");

my $decoded = (client->ajax_post_decode(
  '/files/nodes',
  [ node => "root/Rapi-Fs-Dist/$dir", root_node => 1 ]
)) || [];

my @names = map { $_->{name} } @$decoded;
shift @names; #<-- the up/link node

is_deeply(
  [sort @names],
  [sort @real],
  "Node fetch matches real files on disk"
);


done_testing;
