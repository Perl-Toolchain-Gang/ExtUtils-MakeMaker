#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

use strict;

use File::Spec;
use File::Temp qw[tempdir];
use MakeMaker::Test::Setup::PL_FILES;
use MakeMaker::Test::Utils;
use IPC::Cmd qw(can_run);
use Test::More
    can_run(make())
    ? (tests => 9)
    : (skip_all => "make not available");

my $perl = which_perl();
my $make = make_run();
perl_lib();

my $tmpdir = tempdir( DIR => 't', CLEANUP => 1 );
chdir $tmpdir;

setup;

END {
    ok( chdir File::Spec->updir );
    ok( teardown );
}

ok chdir('PL_FILES-Module');

run(qq{$perl Makefile.PL});
cmp_ok( $?, '==', 0 );

my $make_out = run("$make");
is( $?, 0 ) || diag $make_out;

foreach my $file (qw(single.out 1.out 2.out blib/lib/PL/Bar.pm)) {
    ok( -e $file, "$file was created" );
}
