# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Zilla::Plugin::BundleInspector;
# ABSTRACT: Gather prereq and config info from PluginBundles

use Moose;
use MooseX::AttributeShortcuts;
use Dist::Zilla::Config::BundleInspector;

with qw(
  Dist::Zilla::Role::FileMunger
  Dist::Zilla::Role::PrereqSource
);

sub mvp_multivalue_args { qw( bundle ) }

has file_name_re => (
  is         => 'ro',
  isa        => 'RegexpRef',
  default    => sub {
    qr{(?: ^lib/ )? ( (?: [^/]+/ )+ PluginBundle/.+? ) \.pm$}x
  },
);

# coerce
around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);

  foreach my $re ( qw(
    file_name_re
  ) ){
    # upgrade Str to RegExp
    $args->{ $re } = qr/$args->{ $re }/
      if exists $args->{ $re };
  }

  return $args;
};

=attr bundle

Specify the name of a bundle to inspect.
Can be used multiple times.

If none are specified the plugin will attempt to discover
any included bundles.

=cut

has bundles => (
  is         => 'lazy',
  isa        => 'ArrayRef',
  init_arg   => 'bundle',
);

sub _build_bundles {
  my ($self) = @_;
  # TODO: warn if ./lib/ not found in @INC?
  return [
    map  { s{/}{::}g; $_ } # /r
    # combine map/grep into one... it feels weird, but why do the m// more than once?
    map  { $_->name =~ $self->file_name_re ? $1 : () }
      @{ $self->zilla->files }
  ];
}

has inspectors => (
  is         => 'lazy',
  isa        => 'HashRef',
  init_arg   => undef,
);

sub _build_inspectors {
  my ($self) = @_;
  return {
    map {
      ($_ => Dist::Zilla::Config::BundleInspector->new({ bundle_class => $_ }))
    }
      @{ $self->bundles }
  };
}

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    %{ $_->prereqs->as_string_hash }
  )
    for values %{ $self->inspectors };
}

sub munge_file {
  my ($self, $file) = @_;

  return
    # FIXME: build up a list? join('|', map { s{::}{/}g; $_ } @{ $self->bundles })?
    unless my $class = ($file->name =~ $self->file_name_re)[0];

  $class =~ s{/}{::}g;

  return
    unless my $inspector = $self->inspectors->{ $class };

  my $content = $file->content;
  my $ini_string = $inspector->ini_string;
  chomp $ini_string;

  # prepend spaces to make verbatim paragraph
  $ini_string =~ s/^(.+)$/  $1/mg;

  $content =~ s/^=bundle_ini_string$/$ini_string/m;
  $file->content($content);

  return;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

  ; in dist.ini
  [Bootstrap::lib]
  [BundleInspector]

=head1 DESCRIPTION

This plugin is useful when using L<Dist::Zilla> to release
a plugin bundle for L<Dist::Zilla> or L<Pod::Weaver>
(others could be supported in the future).

Each bundle inspected will be loaded to gather the plugin specs.
B<Note> that this means you will probably want to use
L<Dist::Zilla::Plugin::Bootstrap::lib>
in order to inspect the included bundle
(rather than an older, installed version).

This plugin does L<Dist::Zilla::Role::PrereqSource>
and the bundle's plugin specs will be used
to determine additional prereqs for the dist.

Additionally this plugin does L<Dist::Zilla::Role::FileMunger>
so that if you include a line in the pod of your plugin bundle
of exactly C<=bundle_ini_string> it will be replaced with
a verbatim block of the roughly equivalent INI config for the bundle.

=head1 SEE ALSO

=for :list
* L<Config::MVP::Writer::INI>
* L<Config::MVP::BundleInspector>
* L<Dist::Zilla::Config::BundleInspector>

=cut
