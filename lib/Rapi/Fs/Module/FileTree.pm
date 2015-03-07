package Rapi::Fs::Module::FileTree;

use strict;
use warnings;

# ABSTRACT: ExtJS tree for Rapi::Fs::Driver filesystems

use Moose;
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

has 'tree_search_timeout', is => 'ro', isa => Int, default => sub { 30 };
has 'max_nodes_per_fetch', is => 'ro', isa => Int, default => sub { 2000 };


sub BUILD {
  my $self = shift;
  
  $self->apply_extconfig(
    tabTitle   => 'File Tree',
    tabIconCls => 'ra-icon-folders'
  );
  
  $self->add_plugin('apptree-serverfilter');
  
}

around call_fetch_nodes => sub {
  my ($orig, $self, @args) = @_;
  
  local $self->{_nodes_fetched}     = $self->{_nodes_fetched}     // 0;
  local $self->{_max_nodes_reached} = $self->{_max_nodes_reached} // 0;
  local $self->{_tree_search_start} = $self->{_tree_search_start} || time;
  
  $self->$orig(@args)
};

sub fetch_nodes {
  my ($self, $node) = @_;
  
  return $self->mounts_nodes if ($node eq 'root');
  
  my ($prefix, $enc_path) = split(/\//,$node,2);
  die "Malformed node path '$node'" unless ($prefix eq 'root');
  
  my ($mount, $path) = split(/\//,$self->b64_decode($enc_path),2);
  
  my $Mount = $self->get_mount($mount);
  
  # Check if this is the root node (i.e. a local root of a sub-dir)
  my $loc_root = $self->c->req->params->{root_node} ? 1 : 0;
  delete $self->c->req->params->{root_node} if ($loc_root);
  my @items = ( $loc_root ? $self->_folder_up_treenode($path,$mount) : () );
  
  my @dirs  = ();
  my @files = ();
  
  $_->is_dir ? push @dirs, $_ : push @files, $_ for sort {
    $a->name cmp $b->name
  } $Mount->node_get_subnodes($path || '/');
  
  # prelim proof-of-concept:
  my $recurse = 0;
  if (my $search = $self->c->req->params->{search}) {
    @files = grep {
      $_->name =~ /\Q${search}\E/i
    } @files;
    $recurse = $search;
    
    local $self->{_recur_depth} = $self->{_recur_depth} || 0;
    $self->{_recur_depth}++;
    $recurse = 0 if ($self->{_recur_depth} > $self->max_recursive_fetch_depth);
    
    if((time - $self->{_tree_search_start}) >= $self->tree_search_timeout) {
      $recurse = 0;
      $self->c->set_response_warning({
        title => 'Search timeout exceeded',
        msg => join('',
          'The search timeout (',$self->tree_search_timeout,' secs) was reached before ',
          'traversing all sub-directories -- only matches found so far (',$self->{_nodes_fetched}, 
          ') are shown. Try searching on a smaller directory or increase "tree_search_timeout"'
        )
      });
      $self->{_max_nodes_reached} = 1;
    }
    $self->{_recur_depth} = $self->max_recursive_fetch_depth + 1; #<-- so other chains will stop also
  }
  
  return [
    @items,
    map { $self->_fs_to_treenode($_,$mount,$recurse) } @dirs, @files
  ];
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
  
  unless ($Node->is_dir || $Node->is_link) {
    $Node->download_url( join('',$Node->view_url,'?method=download'));
    $Node->open_url( join('',$Node->view_url,'?method=open')) if (
         $Node->bytes < $self->max_render_bytes
      && $self->_get_render_content_type( $Node )
    )
  }
  
  $enc_path
}

sub _fs_to_treenode {
  my ($self, $Node, $mount, $recurse) = @_;
  
  return () if ($self->{_max_nodes_reached});
  if($self->{_nodes_fetched} >= $self->max_nodes_per_fetch) {
    $self->{_max_nodes_reached} = 1;
    $self->c->set_response_warning({
      title => 'Max results reached',
      msg => join('',
        'Too many results -- only the first ',$self->{_nodes_fetched}, ' items shown'
      )
    });
    return ();
  }
  
  $self->{_nodes_fetched}++;
  
  my $enc_path = $self->_apply_node_view_url($Node,$mount);
  my $id = join('/','root',$enc_path);

  my $treenode = {
    id       => $id,
    name     => $Node->name,
    text     => $Node->name,
    leaf     => $Node->is_dir ? 0 : 1,
    loaded   => $Node->is_dir ? 0 : 1,
    expanded => $Node->is_dir ? 0 : 1,
    url      => $Node->view_url,
    $Node->is_dir ? () : ( iconCls => $Node->iconCls )
  };
  
  if ($Node->is_dir && $recurse) {
    my $children = $self->fetch_nodes($id);
    
    if (scalar(@$children) > 0) {
      delete $treenode->{expanded};
      $treenode->{expand} = \1 ;
    }
    else {
      # Prune empty unless the dir name matches the search:
      unless ($Node->name =~ /\Q${recurse}\E/i) {
        $self->{_nodes_fetched}--;
        return ();
      }
      $treenode->{loaded} = \1;
      $treenode->{expanded} = \1;
      $treenode->{iconCls} = 'ra-icon-folder';
    }
    
    $treenode->{children} = $children;
  }
  
  return $treenode;
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


sub _folder_up_treenode {
  my ($self, $path, $mount) = @_;
  
  my $Mount = $self->get_mount($mount);
  my $Node = $Mount->get_node($path) or return ();
  my $Parent = $Node->parent or return ();
  
  # This node doesn't count against our quota:
  $self->{_nodes_fetched}--;
  
  my $text = '<span class="blue-text-code">..</span>';
  return {
    %{ $self->prepare_node( $self->_fs_to_treenode($Parent,$mount) ) },
    name     => $text,
    text     => $text,
    iconCls  => 'ra-icon-folder-up',
    expanded => 0,
    loaded   => 1,
    leaf     => 1
  }
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
      border => 1,
      setup_tbar => 1
    );
    
    if($Node->is_dir) {
      $self->apply_extconfig(
        tabIconCls => $Node->iconCls || 'ra-icon-folder',
        root => {
          %{ $self->root_node },
          # Set the root node to the local path:
          id => join('/','root',$enc_path)
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
      
      $meth = 'view' if ($Node->is_link);
      
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

        $c->stash->{template}   = $Node->is_link ? 'linkview.html' : 'fileview.html';
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
