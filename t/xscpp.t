#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib/';
}
chdir 't';

use strict;

use MakeMaker::Test::Utils;
use MakeMaker::Test::Setup::XSCPP;

# Disable full compilation test for now.
# TODO: Until some consensus in community will reached.
# use Test::More
#     have_cplusplus()
#     ? (tests => 5)
#     : (skip_all => "ExtUtils::CBuilder not installed or couldn't find a C++ compiler");
use Test::More tests => 5;
use File::Find;
use File::Spec;
use File::Path;

my $Is_VMS = $^O eq 'VMS';
my $perl = which_perl();

chdir 't';

perl_lib;

$| = 1;

ok( setup_xs(), 'setup' );
END {
    chdir File::Spec->updir or die;
    teardown_xs(), 'teardown' or die;
}

ok( chdir('XSCPP-Test'), "chdir'd to XSCPP-Test" ) ||
  diag("chdir failed: $!");

my @mpl_out = run(qq{$perl Makefile.PL});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

my $mf_content = slurp(makefile_name());
like( $mf_content, qr/\bXSTARGET_EXT\b\s*=\s*\.cpp\b/, 'Makefile: XSTARGET_EXT has right value' );
like( $mf_content, qr/\bXSUBPPRUN\b.+\bXSTARGET_EXT\b/, 'Makefile: seems xsubpp generate file with .cpp suffix' );

# Disable full compilation test for now.
# TODO: Until some consensus in community will reached.
# my $make = make_run();
# my $make_out = run("$make");
# is( $?, 0,                                 '  make exited normally' ) ||
#     diag $make_out;
#
# my $test_out = run("$make test");
# is( $?, 0,                                 '  make test exited normally' ) ||
#     diag $test_out;
