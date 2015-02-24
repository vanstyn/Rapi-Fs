package Rapi::Fs::Driver::Filesystem;

use strict;
use warnings;

# ABSTRACT: Standard filesystem driver

use Moo;
extends 'Rapi::Fs::Driver';
use Types::Standard qw(:all);

use RapidApp::Util ':all';
use Path::Class qw( file dir );
use Scalar::Util qw( blessed );

use Rapi::Fs::File;
use Rapi::Fs::Dir;

has 'top_dir', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  die "args must contain a valid directory path" unless ($self->args);
  
  my $dir = dir( $self->args )->resolve;
  die "$dir is not a directory!" unless (-d $dir);
  
  $dir

}, isa => InstanceOf['Path::Class::Dir'];


sub BUILD {
  my $self = shift;
  $self->top_dir; # init
}

sub get_node {
  my ($self, $path) = @_;
  
  return $path if (
    blessed $path &&
    $path->isa('Rapi::Fs::Node') &&
    $path->driver == $self
  );
  
  my $Ent = $self->_path_obj($path) or return undef;
  $self->_node_factory($Ent)
}


sub get_subnodes {
  my ($self, $path) = @_;
  
  my $Ent = $self->_path_obj($path); 

  $Ent && $Ent->is_dir 
    ? map { $self->_node_factory($_) } $Ent->children 
    : ()
}


# Returns a Path::Class::Dir, Path::Class::File or undef
sub _path_obj {
  my ($self, $path) = @_;
  
  defined $path or return undef;
  
  return $self->top_dir if ($path eq '/' || $path eq '');

  my $Ent = $self->top_dir->subdir( $path );
  
  -d $Ent ? $Ent :
  -e $Ent ? $self->top_dir->file($path) : undef
}

sub _node_factory {
  my ($self, $Ent) = @_;
  
  my $class = $Ent->is_dir ? 'Rapi::Fs::Dir' : 'Rapi::Fs::File';
  
  my $path = $Ent->relative($self->top_dir)->stringify;
  $path = '/' if ($path eq '.');
  
  $class->new({
    name          => $path eq '/' ? $self->name : $Ent->basename,
    path          => $path,
    driver        => $self,
    driver_stash  => { path_obj => $Ent }
  })
}


sub _get_node_stat {
  my ($self, $path) = @_;
  my $Node = $self->get_node($path) or return undef;
  $Node->driver_stash->{stat} //= $Node->driver_stash->{path_obj}->stat
}

sub node_get_parent {
  my ($self, $path) = @_;
  my $Node = $self->get_node($path) or return undef;
  $Node->parent_path ? $self->get_node( $Node->parent_path ) : undef
}

sub node_get_parent_path {
  my ($self, $path) = @_;
  my $Node = $self->get_node($path) or return undef;
  
  return undef unless (
    $Node->path &&
    $Node->path ne '' &&
    $Node->path ne '/'
  );
  
  return '/' unless ($Node->path =~ /\//);
  
  my @parts = split(/\//,$Node->path);
  
  pop @parts if (pop @parts eq ''); # handles trailing '/'
  
  my $parent = scalar(@parts) > 0 ? join('/',@parts) : undef;
  $parent && $parent ne '' ? $parent : undef
}


sub node_get_bytes {
  my ($self, $path) = @_;
  my $stat = $self->_get_node_stat($path) or return undef;
  $stat->size
}

sub node_get_mtime {
  my ($self, $path) = @_;
  my $stat = $self->_get_node_stat($path) or return undef;
  $stat->mtime
}


sub node_get_iconCls {
  my ($self, $path) = @_;
  my $Node = $self->get_node($path) or return undef;
  
  # NOTE: this method should not used for dir nodes within ExtJS tree because we want
  # to use the ExtJS default cls which is already a folder with expanded/collapsed states
  if($Node->is_dir) {
    return $Node->path eq '/' 
      ? 'ra-icon-folder-network' 
      : 'ra-icon-folder'
  }
  else {
    return 'ra-icon-document-14x14-light' if ($Node->name =~ /^\./);
    
    my @parts = split(/\./,$Node->name);
    my $ext = scalar(@parts) > 1 ? pop @parts : undef;
    
    return $ext ? "filelink $ext" : 'ra-icon-page-white-14x14';
  }
}



1;
