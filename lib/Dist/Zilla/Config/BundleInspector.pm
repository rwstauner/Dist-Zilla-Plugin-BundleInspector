use strict;
use warnings;

package Dist::Zilla::Config::BundleInspector;
# ABSTRACT: Give Hints to Config::MVP::BundleInspector

use Class::Load ();
use Sub::Override ();

use Moose;
extends 'Config::MVP::BundleInspector';

around _build_bundle_method => sub {
  my ($orig, $self) = @_;
  Class::Load::load_class($self->bundle_class);
  return $self->bundle_class->can('bundle_config')
    ? 'bundle_config'
    : $self->$orig();
};

sub _build_bundle_name {
  my ($self) = @_;
  (my $name = $self->bundle_class) =~ s/.+::PluginBundle::/\@/;
  return $name;
}

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

# secret knowledge about dist-zilla and pod-weaver bundles

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

use String::RewritePrefix
  rewrite => {
    -as      => '__pod_weaver_rewriter',
    prefixes => {
      'Pod::Weaver::PluginBundle::' => '@',
      'Pod::Weaver::Plugin::'       => '-',
      'Pod::Weaver::Section::'      => '',
      ''                            => '=',
    },
  },
  rewrite => {
    -as      => '__dist_zilla_rewriter',
    prefixes => {
      'Dist::Zilla::PluginBundle::' => '@',
      'Dist::Zilla::Plugin::'       => '',
      ''                            => '=',
    },
  };

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

  # exact same usage as Config::MVP::BundleInspector

=head1 DESCRIPTION

This is used internally by L<Dist::Zilla::Plugin::BundleInspector>.
It extends L<Config::MVP::BundleInspector> to add specialized handling
for L<Dist::Zilla> and L<Pod::Weaver> bundles.

=head1 SEE ALSO

=for :list
* L<Config::MVP::BundleInspector>
* L<Dist::Zilla::Plugin::BundleInspector>

=cut
