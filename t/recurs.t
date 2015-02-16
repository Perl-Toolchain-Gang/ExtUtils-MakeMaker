#!/usr/bin/perl -w

# This tests MakeMaker against recursive builds

BEGIN {
    unshift @INC, 't/lib';
}

use strict;
use warnings;
use MakeMaker::Test::Utils;
use Config;
use ExtUtils::MM;
use Test::More
    !MM->can_run(make()) && $ENV{PERL_CORE} && $Config{'usecrosscompile'}
    ? (skip_all => "cross-compiling and make not available")
    : (tests => 23);
use File::Temp qw[tempdir];
use File::Path;

# 'make disttest' sets a bunch of environment variables which interfere
# with our testing.
delete @ENV{qw(PREFIX LIB MAKEFLAGS)};

my $DIRNAME = 'Recurs';
my %FILES = (
    'Makefile.PL'          => <<'END',
use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'Recurs', VERSION => 1.00);
END

    'prj2/Makefile.PL'     => <<'END',
use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'Recurs::prj2', VERSION => 1.00);
END

    # Check if a test failure in a subdir causes make test to fail
    'prj2/t/fail.t'         => <<'END',
#!/usr/bin/perl -w
print "1..1\n";
print "not ok 1\n";
END
);

my $perl = which_perl();
my $Is_VMS = $^O eq 'VMS';

chdir 't';
perl_lib; # sets $ENV{PERL5LIB} relative to t/

my $tmpdir = tempdir( DIR => '../t', CLEANUP => 1 );
use Cwd; my $cwd = getcwd; END { chdir $cwd } # so File::Temp can cleanup
chdir $tmpdir;

my $Touch_Time = calibrate_mtime();

$| = 1;

hash2files($DIRNAME, \%FILES);
END {
    ok( chdir File::Spec->updir );
    ok( rmtree($DIRNAME), 'teardown' );
}

ok( chdir($DIRNAME), q{chdir'd to Recurs} ) ||
    diag("chdir failed: $!");


# Check recursive Makefile building.
my @mpl_out = run(qq{$perl Makefile.PL});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

my $makefile = makefile_name();

ok( -e $makefile, 'Makefile written' );
ok( -e File::Spec->catfile('prj2',$makefile), 'sub Makefile written' );

my $make = make_run();

my $make_out = run("$make");
is( $?, 0, 'recursive make exited normally' ) || diag $make_out;

ok( chdir File::Spec->updir );
ok( rmtree($DIRNAME), 'cleaning out recurs' );
hash2files($DIRNAME, \%FILES);
ok( chdir($DIRNAME), q{chdir'd to Recurs} ) ||
    diag("chdir failed: $!");


# Check NORECURS
@mpl_out = run(qq{$perl Makefile.PL "NORECURS=1"});

cmp_ok( $?, '==', 0, 'Makefile.PL NORECURS=1 exited with zero' ) ||
  diag(@mpl_out);

$makefile = makefile_name();

ok( -e $makefile, 'Makefile written' );
ok( !-e File::Spec->catfile('prj2',$makefile), 'sub Makefile not written' );

$make = make_run();

run("$make");
is( $?, 0, 'recursive make exited normally' );


ok( chdir File::Spec->updir );
ok( rmtree($DIRNAME), 'cleaning out recurs' );
hash2files($DIRNAME, \%FILES);
ok( chdir($DIRNAME), q{chdir'd to Recurs} ) ||
    diag("chdir failed: $!");


# Check that arguments aren't stomped when they have .. prepended
# [rt.perl.org 4345]
@mpl_out = run(qq{$perl Makefile.PL "INST_SCRIPT=cgi"});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);

$makefile = makefile_name();
my $submakefile = File::Spec->catfile('prj2',$makefile);

ok( -e $makefile,    'Makefile written' );
ok( -e $submakefile, 'sub Makefile written' );

my $inst_script = File::Spec->catdir(File::Spec->updir, 'cgi');
ok( open(MAKEFILE, $submakefile) ) || diag("Can't open $submakefile: $!");
{ local $/;
  like( <MAKEFILE>, qr/^\s*INST_SCRIPT\s*=\s*\Q$inst_script\E/m,
        'prepend .. not stomping WriteMakefile args' )
}
close MAKEFILE;


{
    # Quiet "make test" failure noise
    close *STDERR;

    my $test_out = run("$make test");
    isnt $?, 0, 'test failure in a subdir causes make to fail';
}
