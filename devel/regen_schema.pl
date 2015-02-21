#!/usr/bin/perl

use strict;
use warnings;

use DBIx::Class::Schema::Loader;
use Module::Runtime;

use FindBin;
use lib "$FindBin::Bin/../lib";

my $approot = "$FindBin::Bin/..";
my $applib = "$approot/lib";

$ENV{APPHOME} = $approot;

my $model_class = 'Rapi::Fs::Model::DB';
Module::Runtime::require_module($model_class);

my $nfo = $model_class->config->{connect_info};

DBIx::Class::Schema::Loader::make_schema_at(
  $model_class->config->{schema_class}, 
  {
    debug => 1,
    dump_directory => $applib,
    use_moose	=> 1, generate_pod => 0,
    components => ["InflateColumn::DateTime"],
  },
  [ $nfo->{dsn},$nfo->{user},$nfo->{password} ]
);

