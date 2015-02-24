package Rapi::Fs::Driver;

use strict;
use warnings;

# ABSTRACT Base class for all Drivers

use Moo;
use Types::Standard qw(:all);

has 'name', is => 'ro', isa => Str, required => 1;
has 'args', is => 'ro', isa => Maybe[Str], default => sub { undef };


sub get_node        { ... }
sub get_subnodes    { ... }
sub get_file_bytes  { ... }
sub get_node_mtime  { ... }


1;
