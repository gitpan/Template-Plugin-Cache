#============================================================= -*-Perl-*-
#
# Template::Plugin::Cache
#
# DESCRIPTION
#
#   Plugin to cache template output
#
# AUTHORS
#   Perrin Harkins           <perrin@elem.com <mailto:perrin@elem.com>>
#   (your name could be here)
#
# COPYRIGHT
#   Copyright (C) 2001 Perrin Harkins.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::Cache;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;

use Cache::FileCache;

$VERSION = '0.10';

#------------------------------------------------------------------------
# new(\%options)
#------------------------------------------------------------------------

sub new {
    my ($class, $context, $params) = @_;
    my $cache = Cache::FileCache->new($params);
    my $self = bless {
		      CACHE   => $cache,
		      CONFIG  => $params,
		      CONTEXT => $context,
		     }, $class;
    return $self;
}

#------------------------------------------------------------------------
# $cache->include({
#                 template => 'foo.html',
#                 keys     => {'user.name', user.name},
#                 ttl      => 60, #seconds
#                });
#------------------------------------------------------------------------

sub inc {
    my ($self, $params) = @_;
    $self->_cached_action('include', $params);
}

sub proc {
    my ($self, $params) = @_;
    $self->_cached_action('include', $params);
}

sub _cached_action {
    my ($self, $action, $params) = @_;
    my $cache_keys = $params->{keys};
    my $key = join(
		   ':',
		   (
		    $params->{template},
		    map { "$_=$cache_keys->{$_}" } keys %{$cache_keys}
		   )
		  );
    my $result = $self->{CACHE}->get($key);
    if (!$result) {
      $result = $self->{CONTEXT}->$action($params->{template});
      $self->{CACHE}->set($key, $result, $params->{ttl});
    }
    return $result;
}

1;

__END__

=head1 NAME

Template::Plugin::Cache - cache output of templates

=head1 SYNOPSIS

  [% USE cache = Cache%]
    

  [% cache.inc(
	       'template' => 'slow.html',
	       'keys' => {'user.name' => user.name},
	       'ttl' => 360
	       ) %]

=head1 DESCRIPTION

The Cache plugin allows you to cache generated output from a template.
You load the plugin with the standard syntax:

    [% USE cache = Cache %]

This creates a plugin object with the name 'cache'.  You may also
specify parameters for the File::Cache module, which is used for
storage.

    [% USE mycache = Cache(namespace => 'MyCache') %]

The only methods currently available are include and process,
abbreviated to "inc" and "proc" to avoid clashing with built-in
directives.  They work the same as the standard INCLUDE and PROCESS
directives except that they will first look for cached output from the
template being requested and if they find it they will use that
instead of actually running the template.

  [% cache.inc(
	       'template' => 'slow.html',
	       'keys' => {'user.name' => user.name},
	       'ttl' => 360
	       ) %]

The template parameter names the file or block to include.  The keys
are variables used to identify the correct cache file.  Different
values for the specified keys will result in different cache files.
The ttl parameter specifies the "time to live" for this cache file, in
seconds.

Why the ugliness on the keys?  Well, the TT dot notation can only be
resolved correctly by the TT parser at compile time.  It's easy to
look up simple variable names in the stash, but compound names like
"user.name" are hard to resolve at runtime.  I may attempt to fake
this in a future version, but it would be hacky and might cause
problems.

=head1 AUTHORS

Perrin Harkins (perrin@elem.com <mailto:perrin@elem.com>) wrote the
first version of this plugin, with help and suggestions from various
parties.

=head1 COPYRIGHT

Copyright (C) 2001 Perrin Harkins.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<File::Cache|File::Cache>

=cut
