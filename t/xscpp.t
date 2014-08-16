#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib/';
}
chdir 't';

use strict;

use MakeMaker::Test::Utils;
use MakeMaker::Test::Setup::XSCPP;
use Test::More
    have_cplusplus()
    ? (tests => 5)
    : (skip_all => "ExtUtils::CBuilder not installed or couldn't find a C++ compiler");
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

my $make = make_run();
my $make_out = run("$make");
is( $?, 0,                                 '  make exited normally' ) ||
    diag $make_out;

my $test_out = run("$make test");
is( $?, 0,                                 '  make test exited normally' ) ||
    diag $test_out;
