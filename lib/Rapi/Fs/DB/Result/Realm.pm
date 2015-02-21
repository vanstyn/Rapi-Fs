use utf8;
package Rapi::Fs::DB::Result::Realm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("realm");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "driver_class",
  {
    data_type => "varchar",
    default_value => "Filesystem",
    is_nullable => 0,
    size => 64,
  },
  "args",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "extra",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->has_many(
  "directories",
  "Rapi::Fs::DB::Result::Directory",
  { "foreign.realm_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "file_metas",
  "Rapi::Fs::DB::Result::FileMeta",
  { "foreign.realm_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "files",
  "Rapi::Fs::DB::Result::File",
  { "foreign.realm_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2015-02-21 16:46:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v2K1ZSsaJBWh5qmfU6F6mw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
