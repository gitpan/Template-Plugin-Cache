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

$VERSION = '0.12';

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
    $self->_cached_action('process', $params);
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

=head1 QUESTIONS

=head2 How is this different from the caching already built into Template Toolkit?

That cache is for caching the template files and the compiled version
of the templates.  This cache is for caching the actual output from
running a template.

=head2 Who would benefit from this cache?

There are two situations where this might be useful.  The first is if
you are using a plugin or object inside your template that does
something slow, like accessing a database or a disk drive or another
process.  The DBI plugin, for example.  I don't build my apps this way
(I use a pipeline model with all the data collected before the
template is run), but I know some people do.

The other situation is if you have an unusually complex template that
takes a significant amount of time to run.  Template Toolkit is quite
fast, so it's uncommon for the actual template processing to take any
noticeable amount of time, but it is possible in extreme cases.

=head2 Why don't you let users choose which Cache::Cache subclass they want to use?

Because Cache::FileCache is by far the fastest in nearly all cases.

=head2 Will you be offering support for other cache modules?

I could, if there is a demand for it.

=head2 Any "gotchas" I should know about?

If you have a template that produces side effects when run, like
modifying a database or object, these side effects will not be
captured and caching will break them.  The cache only caches actual
template output.

Of course, if you have a template which produces side effects, you are
a very naughty person and you get what you deserve.

=head1 AUTHORS

Perrin Harkins (perrin@elem.com <mailto:perrin@elem.com>) wrote the
first version of this plugin, with help and suggestions from various
parties.

=head1 COPYRIGHT

Copyright (C) 2001 Perrin Harkins.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<Cache::FileCache|Cache::FileCache>

=cut
