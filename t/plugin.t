use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestBundleHelpers;
use Test::DZil;

my $root = dir(qw( t data recovering_the_satellites ));

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
}

done_testing;
