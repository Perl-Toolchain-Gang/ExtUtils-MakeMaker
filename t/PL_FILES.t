#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}
chdir 't';

use strict;
use Config;
use Test::More;

use File::Spec;
use MakeMaker::Test::Setup::PL_FILES;
use MakeMaker::Test::Utils;

my $Skipped = 0;
if( $Config{'usecrosscompile'} ) {
    $Skipped = 1;
    plan skip_all => "no toolchain installed when cross-compiling";
}
else {
    plan tests => 9;
}

my $perl = which_perl();
my $make = make_run();
perl_lib();

setup;

END {
    unless ( $Skipped ) {
        ok( chdir File::Spec->updir );
        ok( teardown );
    }
}

ok chdir('PL_FILES-Module');

run(qq{$perl Makefile.PL});
cmp_ok( $?, '==', 0 );

my $make_out = run("$make");
is( $?, 0 ) || diag $make_out;

foreach my $file (qw(single.out 1.out 2.out blib/lib/PL/Bar.pm)) {
    ok( -e $file, "$file was created" );
}
