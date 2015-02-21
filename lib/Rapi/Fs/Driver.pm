package Rapi::Fs::Driver;

use strict;
use warnings;

# ABSTRACT Base class for all Drivers

use Moo;
use Types::Standard qw(:all);


has 'args', is => 'ro', isa => Maybe[Str], default => sub { undef };



1;
