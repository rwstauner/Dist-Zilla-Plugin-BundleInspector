use strict;
use warnings;

package # no_index
  TestBundleHelpers;

use Path::Class qw( file dir );
use Test::More;
use Test::Differences;

our @EXPORT = qw(
  eq_or_diff
  file
  dir
);

sub import {
  my $pkg = caller;
  no strict 'refs';
  *{ $pkg . '::' . $_ } = \&$_
    for @EXPORT;
}

1;
