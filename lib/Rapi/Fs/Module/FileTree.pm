package Rapi::Fs::Module::FileTree;

use strict;
use warnings;

# ABSTRACT: ExtJS tree for Rapi::Fs::Driver filesystems

use Moo;
extends 'RapidApp::Module::NavTree';
with 'Rapi::Fs::Module::Role::Mounts';

use Types::Standard qw(:all);
use URI;

use RapidApp::Util qw(:all);

# These are from parent classes, but we're declaring fresh since they're Moose and we're Moo:
has 'fetch_nodes_deep', is => 'ro', isa => Bool, default => sub {0};
has 'use_contextmenu',  is => 'ro', isa => Bool, default => sub {1};

# Max file size to attempt to render
has 'max_render_bytes', is => 'ro', isa => Int, default => sub { 4*1024*1024 }; # 4MB


sub BUILD {
  my $self = shift;
  
  $self->apply_extconfig(
    tabTitle   => 'File Tree',
    tabIconCls => 'ra-icon-folders'
  );
}


sub fetch_nodes {
  my ($self, $node) = @_;
  
  return $self->mounts_nodes if ($node eq 'root');
  
  my ($prefix, $enc_path) = split(/\//,$node,2);
  die "Malformed node path '$node'" unless ($prefix eq 'root');
  
  my ($mount, $path) = split(/\//,$self->b64_decode($enc_path),2);
  
  my $Mount = $self->get_mount($mount);
  
  my @dirs  = ();
  my @files = ();
  
  $_->is_dir ? push @dirs, $_ : push @files, $_ for sort {
    $a->name cmp $b->name
  } $Mount->node_get_subnodes($path || '/');
  
  return [ map { $self->_fs_to_treenode($_,$mount) } @dirs, @files ];
}


sub _get_render_content_type {
  my ($self, $Node) = @_;
  return undef if ($Node->is_dir);

  my $ct = $Node->content_type;

  # Safe render as-is:
  return $ct if (
        $ct =~ /^image\//
    ||  $ct =~ /^video\//
    ||  $ct =~ /^text\/html/
    ||  $ct =~ /^application\/pdf/
  );

  $Node->is_text && $Node->text_encoding 
    ? join('','text/plain; charset=',$Node->text_encoding) 
    : undef
}

sub _apply_node_view_url {
  my ($self, $Node, $mount) = @_;
  
  my $enc_path = $Node->path && $Node->path ne '/'
    ? $self->b64_encode(join('/',$mount,$Node->path))
    : $self->b64_encode($mount);
    
  $Node->view_url( $self->suburl($enc_path) );
  
  unless ($Node->is_dir) {
    $Node->download_url( join('',$Node->view_url,'?method=download'));
    $Node->open_url( join('',$Node->view_url,'?method=open')) if (
         $Node->bytes < $self->max_render_bytes
      && $self->_get_render_content_type( $Node )
    )
  }
  
  $enc_path
}

sub _fs_to_treenode {
  my ($self, $Node, $mount) = @_;
  
  my $enc_path = $self->_apply_node_view_url($Node,$mount);

  return {
    id       => join('/','root',$enc_path),
    name     => $Node->name,
    text     => $Node->name,
    leaf     => $Node->is_dir ? 0 : 1,
    loaded   => $Node->is_dir ? 0 : 1,
    expanded => $Node->is_dir ? 0 : 1,
    url      => $Node->view_url,
    $Node->is_dir ? () : ( iconCls => $Node->iconCls )
  }
}


sub mounts_nodes {
  my $self = shift;
  
  return [ map {
    my $enc_path = $self->b64_encode($_->name);
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
  
  if (my $Node = $self->Node_from_local_args) {
  
    my $mount    = $Node->driver->name;
    my $enc_path = $self->b64_encode( 
      join('/',$mount,$Node->path eq '/' ? '' : $Node->path) 
    );
    
    $self->apply_extconfig(
      tabTitle => $Node->path eq '/' ? $mount : $Node->name,
      autoScroll => 1,
      border => 1
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
        tabIconCls => $Node->iconCls || 'ra-icon-folder',
        root => {
          %{ $self->root_node },
          children => $children
        }
      );
    
    }
    else {
      
      my $c = $self->c;
      my $meth = $c->req->params->{method} ||
        # If there was no supplied method, the default is 'view' which renders
        # the fileview.html template page to view the file info. However, if the
        # request was "referred" internally and is *not* a request from the Ajax
        # JS client, we set the default method to 'open' which renders the file
        # directly. This logic allows html-content which is rendered in an iframe
        # to be able to properly fetch its own links, like css, js and images,
        # all work as expected:
        $self->_is_self_referred_request && !$c->is_ra_ajax_req ? 'open' : 'view';
      
      if($meth eq 'download' || $meth eq 'open') {
        my $fh = $Node->fh or die usererr "Failed to obtain filehandle!";
        
        my $h = $c->res->headers;
        
        if($meth eq 'open') {
          my $ct = $self->_get_render_content_type( $Node );
          $ct ? $h->content_type( $ct ) : $meth = 'download'
        }
        
        if($meth eq 'download') {
          $h->header('Content-disposition' => join('','attachment; filename="',$Node->name,'"'));
          $h->content_type( $Node->content_type );
        }
        
        $h->content_length( $Node->bytes );
        $h->last_modified( $Node->mtime || time );
        $h->expires(time());
        $h->header('Pragma' => 'no-cache');
        $h->header('Cache-Control' => 'no-cache');
        
        $c->res->body( $fh );
        
        return $c->detach;
      }
      elsif($meth eq 'view') {
      
        $self->_apply_node_view_url($Node,$mount);
        $self->_apply_node_view_url($Node->parent,$mount);

        $c->stash->{template}   = 'fileview.html';
        $c->stash->{RapiFsFile} = $Node;

        return $c->detach( $c->view('RapidApp::Template') );
      }
      else {
        die usererr "No such method '$meth'";
      
      }
      
    }

  }
  
  $self->$orig(@args)
};


sub _is_self_referred_request {
  my $self = shift;
  
  my $c = $self->c;
  if( my $rUri = $c->req->referer ? URI->new( $c->req->referer ) : undef ) {
    return $c->req->uri->host_port eq $rUri->host_port
  }
  return 0;
}


around 'auto_hashnav_redirect_current' => sub {
  my ($orig, $self, @args) = @_;
  
  my $uri_query = $self->c->req->uri->query || '';
  
  $self->$orig(@args) unless (
    # Stop hashnav_redirect for referrers from ourself
    $self->_is_self_referred_request
    
    # Or in the case of a supplied known method param
    || $uri_query eq 'method=open'
    || $uri_query eq 'method=download'
  )
};




1;
