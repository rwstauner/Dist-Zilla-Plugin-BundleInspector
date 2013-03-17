# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Zilla::Plugin::BundleInspector;
# ABSTRACT: Gather prereq and config info from PluginBundles

use Moose;
use MooseX::AttributeShortcuts;
use Dist::Zilla::Config::BundleInspector;

with qw(
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

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
