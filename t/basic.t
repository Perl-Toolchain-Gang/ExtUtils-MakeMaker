#!/usr/bin/perl -w

# This test puts MakeMaker through the paces of a basic perl module
# build, test and installation of the Big::Fat::Dummy module.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use strict;
use Test::More tests => 8;
use MakeMaker::Test::Utils;
use File::Spec;
use TieOut;

my $perl = which_perl;
perl_lib;

$| = 1;

ok( chdir 'Big-Fat-Dummy', "chdir'd to Big-Fat-Dummy" ) ||
  diag("chdir failed: $!");

my @mpl_out = `$perl Makefile.PL PREFIX=dummy-install`;

cmp_ok( $?, '==', 0, 'Makefile.PL exited with non-zero' ) ||
  diag(@mpl_out);
ok( grep(/^Writing Makefile for Big::Fat::Dummy/, @mpl_out) == 1,
                                           'Makefile.PL output looks right');

my $makefile = makefile_name();
ok( -e $makefile,       'Makefile exists' );
ok( -M $makefile <= 0,  '  its been touched' );

END { unlink makefile_name(), makefile_backup() }

open(STDERR, ">&STDOUT") || die $!;
my $manifest_out = `make manifest`;
ok( -e 'MANIFEST',      'make manifest created a MANIFEST' );
ok( -s 'MANIFEST',      '  its not empty' );

END { unlink 'MANIFEST'; }


my $make = make();

my $test_out = `$make test`;
like( $test_out, qr/All tests successful/, 'make test' );
