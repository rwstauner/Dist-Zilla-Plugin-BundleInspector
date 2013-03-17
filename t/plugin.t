use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestBundleHelpers;
use Test::DZil;

my $root = dir(qw( t data recovering_the_satellites ));
eval "use lib '${\ $root->subdir(q[lib])->as_foreign(q[Unix])->absolute->stringify }'";

{
  my $tzil = Builder->from_config(
    {
      dist_root => $root,
    },
  );
  $tzil->build;

  is_filelist $tzil->files, [qw(
    dist.ini
    lib/Dist/Zilla/PluginBundle/Catapult.pm
    lib/Pod/Weaver/PluginBundle/ChildrenInBloom.pm
  )], 'included files';

  is_deeply $tzil->prereqs->as_string_hash->{runtime}{requires}, {
    'Dist::Zilla::PluginBundle::Goodnight'   => 2.2,
    'Dist::Zilla::Plugin::Angels'            => 3,
    'Dist::Zilla::Plugin::Daylight'          => 0,
    'Dist::Zilla::Plugin::ImNotSleeping'     => 0,
    'Dist::Zilla::Role::PluginBundle::Easy'  => 0.001,
    'Pod::Weaver::Plugin::SeenMeLately'      => 0,
    'Pod::Weaver::Section::Angels'           => '1.23',
    'Pod::Weaver::Section::Another'          => 0,
  }, 'prereqs added';

  test_munged_pod(
    $tzil,
    $root,
    [
      file(qw( lib Dist Zilla PluginBundle Catapult.pm )),
      <<'INI',
=head1 Config

=bundle_ini_string

=cut
INI
      <<'INI',
=head1 Config

  [Angels / @Catapult/Of::The::Silences]
  :version = 3

  [Daylight / @Catapult/Fading]
  [ImNotSleeping]

  [@Goodnight]
  :version = 2.2
  to       = Elisabeth

=cut
INI
    ],
    [
      file(qw( lib Pod Weaver PluginBundle ChildrenInBloom.pm )),
      <<'INI',
=head1 INI

=bundle_ini_string

=cut
INI
      <<'INI',
=head1 INI

  [-SeenMeLately / HaveYou]

  [Angels / Millers]
  :version = 1.23

  [Another / HorseDreamersBlues]

=cut
INI
    ],
  );
}

done_testing;

sub test_munged_pod {
  my ($tzil, $root, @tests) = @_;

  foreach my $test ( @tests ){
    my ($file, $orig, $munged) = @$test;

    pod_eq_or_diff
      disk_file($root, $file)->slurp,
      $orig,
      'disk file has pod placeholder';

    pod_eq_or_diff
      zilla_file($file, $tzil->files)->content,
      $munged,
      'zilla file munges in INI string';
  }
}
