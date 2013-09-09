#!/usr/bin/perl -w

# Ensure pm_to_blib runs at the right times.

use strict;
use lib 't/lib';

use Config;
use Test::More;

use ExtUtils::MakeMaker;

use MakeMaker::Test::Utils;
use MakeMaker::Test::Setup::BFD;

my $Skipped = 0;
if( $Config{'usecrosscompile'} ) {
    $Skipped = 1;
    plan skip_all => "no toolchain installed when cross-compiling";
}
else {
    plan 'no_plan';
}


my $perl     = which_perl();
my $makefile = makefile_name();
my $make     = make_run();


# Setup our test environment
{
    chdir 't';

    perl_lib;

    ok( setup_recurs(), 'setup' );
    END {
        unless ( $Skipped ) {
            ok( chdir File::Spec->updir );
            ok( teardown_recurs(), 'teardown' );
        }
    }

    ok( chdir('Big-Dummy'), "chdir'd to Big-Dummy" ) ||
      diag("chdir failed: $!");
}


# Run make once
{
    run_ok(qq{$perl Makefile.PL});
    run_ok($make);

    ok( -e "blib/lib/Big/Dummy.pm", "blib copied pm file" );
}


# Change a pm file, it should be copied.
{
    # Wait a couple seconds else our changed file will have the same timestamp
    # as the blib file
    sleep 2;

    ok( open my $fh, ">>", "lib/Big/Dummy.pm" ) or die $!;
    print $fh "Something else\n";
    close $fh;

    run_ok($make);
    like slurp("blib/lib/Big/Dummy.pm"), qr/Something else\n$/;
}


# Rerun the Makefile.PL, pm_to_blib should rerun
{
    run_ok(qq{$perl Makefile.PL});

    # XXX This is a fragile way to check that it reran.
    like run_ok($make), qr/^Skip /ms;

    ok( -e "blib/lib/Big/Dummy.pm", "blib copied pm file" );
}
