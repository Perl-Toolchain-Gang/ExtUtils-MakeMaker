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
use Test::More tests => 11;
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

my $makefile = makefile_name();
ok( grep(/^Writing $makefile for Big::Fat::Dummy/, 
         @mpl_out) == 1,
                                           'Makefile.PL output looks right');

ok( -e $makefile,       'Makefile exists' );

# -M is flakey on VMS.
my $mtime = (stat($makefile))[9];
ok( ($^T - $mtime) <= 0,  '  its been touched' );

END { unlink makefile_name(), makefile_backup() }

# Supress 'make manifest' noise
open(STDERR, ">&STDOUT") || die $!;
my $make = make_run();
my $manifest_out = `$make manifest`;
ok( -e 'MANIFEST',      'make manifest created a MANIFEST' );
ok( -s 'MANIFEST',      '  its not empty' );

END { unlink 'MANIFEST'; }

my $test_out = `$make test`;
like( $test_out, qr/All tests successful/, 'make test' );
is( $?, 0 );

my $dist_test_out = `$make disttest`;
is( $?, 0, 'disttest' ) || diag($dist_test_out);

my $realclean_out = `$make realclean`;
is( $?, 0, 'realclean' ) || diag($realclean_out);

