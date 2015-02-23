package Rapi::Fs::Module::FileTree;

use strict;
use warnings;

# ABSTRACT: ExtJS tree for Rapi::Fs::Driver filesystems

use Moo;
extends 'RapidApp::Module::NavTree';
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

# These are from parent classes, but we're declaring fresh since they're Moose and we're Moo:
has 'accept_subargs',   is => 'rw', isa => Bool, default => sub {1};
has 'fetch_nodes_deep', is => 'ro', isa => Bool, default => sub {0};


## ----
## Our own, modified base64 encode/decode using '-' instead of '/'
#use MIME::Base64;
#
#sub b64_encode {
#  my $str = MIME::Base64::encode($_[0]);
#  $str =~ s/\//\-/g;
#  $str =~ s/\r?\n//g;
#  $str
#}
#
#sub b64_decode {
#  my $str = shift;
#  $str =~ s/\-/\//g;
#  MIME::Base64::decode($str)
#}
## ----

# ^^ Special base64 encoding not really needed at this point, 
#    turn off w/ raw passthrough:
sub b64_encode { (shift) }
sub b64_decode { (shift) }



has 'mounts', is => 'ro', isa => ArrayRef[InstanceOf['Rapi::Fs::Driver']], required => 1;

has 'mounts_ndx', is => 'ro', lazy => 1, init_arg => undef, default => sub {
  my $self = shift;
  return { map { $_->name => $_ } @{$self->mounts} }
}, isa => HashRef;

sub BUILD {
  my $self = shift;
  
  my @mounts = @{ $self->mounts };
  die "Must supply at least one Rapi::Fs::Driver mount in mounts!" if (@mounts == 0);
  
  my %seen = ();
  $seen{$_->name}++ and die join(' ',"Duplicate mount name",$_->name) for (@mounts);
  
  $self->mounts_ndx; #init
  
  $self->apply_extconfig(
    tabTitle   => 'File Tree',
    tabIconCls => 'ra-icon-folders'
  );
  
  #$self->accept_subargs(1);
}


sub fetch_nodes {
  my ($self, $node) = @_;
  
  return $self->mounts_nodes if ($node eq 'root');
  
  my ($prefix, $enc_path) = split(/\//,$node,2);
  die "Malformed node path '$node'" unless ($prefix eq 'root');
  
  my ($mount, $path) = split(/\//,&b64_decode($enc_path),2);
  
  my $Mount = $self->mounts_ndx->{$mount} or die "No such mount '$mount'";
  
  my @dirs  = ();
  my @files = ();
  
  $_->is_dir ? push @dirs, $_ : push @files, $_ for sort {
    $a->name cmp $b->name
  } $Mount->get_subnodes($path || '/');
  
  return [ map { $self->_fs_to_treenode($_,$mount) } @dirs, @files ];
}

sub _fs_to_treenode {
  my ($self, $Node, $mount) = @_;
  
  my $enc_path = $Node->path && $Node->path ne '/'
    ? &b64_encode(join('/',$mount,$Node->path))
    : &b64_encode($mount);

  return {
    id       => join('/','root',$enc_path),
    name     => $Node->name,
    text     => $Node->name,
    leaf     => $Node->is_dir ? 0 : 1,
    loaded   => $Node->is_dir ? 0 : 1,
    expanded => $Node->is_dir ? 0 : 1,
    url      => $self->suburl($enc_path) 
  }
}


sub mounts_nodes {
  my $self = shift;
  
  return [ map {
    my $enc_path = &b64_encode($_->name);
    {
      id       => join('/','root',$enc_path),
      name     => $_->name,
      text     => $_->name,
      iconCls  => 'ra-icon-folder-network',
      expanded => 0,
      url      => $self->suburl($enc_path) 
    }
  } @{$self->mounts} ]
}


around 'content' => sub {
  my ($orig,$self,@args) = @_;
  
  my @largs = $self->local_args;
  
  if(@largs > 0) {
  
    my $enc_path = join('/',@largs);
    my ($mount, $path) = split(/\//,&b64_decode($enc_path),2);
  
    my $Mount = $self->mounts_ndx->{$mount} or die usererr "No such mount '$mount'";
    
    my $Node = $Mount->get_node($path || '/');
    
    $self->apply_extconfig(
      tabTitle => $Node->name,
      autoScroll => 1
    );
    
    if($Node->is_dir) {
    
      my $children = $self->call_fetch_nodes( join('/','root',$enc_path) );
      
      if(my $Parent = $Node->parent) {
        my $text = '<span class="blue-text-code">..</span>';
        unshift @$children, {
          %{ $self->prepare_node( $self->_fs_to_treenode($Parent,$mount) ) },
          name     => $text,
          text     => $text,
          iconCls  => 'ra-icon-folder-up',
          expanded => 0,
          loaded   => 1,
          leaf     => 1
        };
      }
      
      # Set the top-level children to the nodes of the supplied path:
      $self->apply_extconfig(
        tabIconCls => 'ra-icon-folder',
        root => {
          %{ $self->root_node },
          children => $children
        }
      );
    
    }
    else {
      # TODO, forward to a file view page...
      
      die usererr "Is a file - not yet implemented...";
    }
  
  
  }
  
  $self->$orig(@args)
};


1;
