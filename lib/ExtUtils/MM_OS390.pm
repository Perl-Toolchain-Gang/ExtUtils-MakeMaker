package ExtUtils::MM_OS390;

use strict;
our $VERSION = '7.47_01';
$VERSION =~ tr/_//d;

use ExtUtils::MakeMaker::Config;
require ExtUtils::MM_Unix;
our @ISA = qw(ExtUtils::MM_Unix);

=head1 NAME

ExtUtils::MM_OS390 - OS390 specific subclass of ExtUtils::MM_Unix

=head1 SYNOPSIS

  Don't use this module directly.
  Use ExtUtils::MM and let it choose.

=head1 DESCRIPTION

This is a subclass of L<ExtUtils::MM_Unix> which contains functionality for
OS390.

Unless otherwise stated it works just like ExtUtils::MM_Unix.

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

=cut


1;
