use strict;
use warnings;

package Dist::Zilla::Config::BundleInspector;
# ABSTRACT: Give Hints to Config::MVP::BundleInspector

use Sub::Override ();

use Moose;
extends 'Config::MVP::BundleInspector';

around _build_bundle_method => sub {
  my ($orig, $self) = @_;
  return $self->bundle_class->can('bundle_config')
    ? 'bundle_config'
    : $self->$orig();
};

sub _build_bundle_name {
  my ($self) = @_;
  (my $name = $self->bundle_class) =~ s/.+::PluginBundle::/\@/;
  return $name;
};

around _plugin_specs_from_bundle_method => sub {
  my ($orig, $self, $class, $method) = @_;

  # override the add_bundle of dzil's PluginBundle::Easy to preserve the bundle spec
  # rather than expanding it to the plugins
  my $over = $class->DOES('Dist::Zilla::Role::PluginBundle::Easy') &&
    Sub::Override->new("${class}::add_bundle" => \&__override_dzil_add_bundle);

  return $self->$orig($class, $method);
};

sub _build_ini_opts {
  my ($self) = @_;

  my $app = __pkg_to_app($self->bundle_class);
  my $rewriter = $self->can("__${app}_rewriter");

  return {
    ($rewriter ? (rewrite_package => $rewriter) : ()),
  };
}

sub __override_dzil_add_bundle {
  my ($self, $bundle, $payload) = @_;
  my $package = $bundle;

  # mimic Easy
  $package =~ s/^\@?/Dist::Zilla::PluginBundle::/
    unless $package =~ /^=/;
  $bundle = "\@$bundle" unless $bundle =~ /^@/;

  # preserve bundle spec (rather than expanding it)
  push @{ $self->plugins }, [ $bundle => $package, $payload || {} ];
}

sub __pkg_to_app {
  (my $app = $_[0]) =~ s/::PluginBundle.+$//;
  $app =~ s/::/_/g;
  return lc $app;
}

sub __dist_zilla_rewriter {
  local $_ = $_[0];
  my $prefix = 'Dist::Zilla::';

    s/^${prefix}PluginBundle::/\@/ or
    s/^${prefix}Plugin::// or
    s/^/=/;

  return $_;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
