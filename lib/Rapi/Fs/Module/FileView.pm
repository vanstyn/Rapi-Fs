package Rapi::Fs::Module::FileView;

use strict;
use warnings;

# ABSTRACT: Viewer for individual files

use Moo;
extends 'RapidApp::Module::ExtComponent';
with 'Rapi::Fs::Module::Role::Mounts';

use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

sub BUILD {
  my $self = shift;
  
  $self->apply_extconfig(
    xtype => 'panel'
  );
  
  $self->apply_actions(
    view     => 'view',
    download => 'download'
  );
}


# IN PROGRESS ......



sub view {
  my $self = shift;
  
  my $c = $self->c;
  my $TC = $c->template_controller;
  
  my $Node = $self->Node_from_local_args or die "not found";
  
  die "is a directory!" if ($Node->is_dir);
  
  $c->res->body( $TC->template_render('fileview.html', {
    File => $Node
  });
  
}

sub download {
  my $self = shift;

}



1;
