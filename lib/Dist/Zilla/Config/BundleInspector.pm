use strict;
use warnings;

package Dist::Zilla::Config::BundleInspector;
# ABSTRACT: Give Hints to Config::MVP::BundleInspector

use Moose;
extends 'Config::MVP::BundleInspector';

__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
