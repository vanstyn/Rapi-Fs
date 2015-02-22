package Rapi::Fs::Node;

use strict;
use warnings;

# ABSTRACT Base class for Dir and File objects

use Moo;
use Types::Standard qw(:all);

has 'driver', is => 'ro', isa => InstanceOf['Rapi::Fs::Driver'], required => 1;
has 'path',   is => 'ro', isa => Str, required => 1;
has 'name',   is => 'ro', isa => Str, required => 1;

sub is_dir { 0 }
sub subnodes { [] }



1;
