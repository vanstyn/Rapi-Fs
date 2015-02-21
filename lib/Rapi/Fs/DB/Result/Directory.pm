use utf8;
package Rapi::Fs::DB::Result::Directory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("directory");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "realm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pid",
  {
    data_type      => "integer",
    default_value  => \"null",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sync_ts",
  { data_type => "datetime", is_nullable => 0 },
  "check_val",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "mtime",
  { data_type => "integer", is_nullable => 0 },
  "ctime",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "directories",
  "Rapi::Fs::DB::Result::Directory",
  { "foreign.pid" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "files",
  "Rapi::Fs::DB::Result::File",
  { "foreign.did" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "pid",
  "Rapi::Fs::DB::Result::Directory",
  { id => "pid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "realm",
  "Rapi::Fs::DB::Result::Realm",
  { id => "realm_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2015-02-21 16:46:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DYUNmCRSt3Qjb+hDZrU3yw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
