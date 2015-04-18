use strict;
use warnings;

use Test::More tests => 6;
use File::Temp 'tempdir';

use File::Spec::Functions qw/catfile catdir/;
use File::Path 'mkpath';
use Cwd 'cwd';

use IPC::Open3;
use Symbol 'gensym';
use Env qw(@PERL5LIB $PERL_MM_OPT);

# ABSTRACT: Test basic behaviour

my $install = tempdir();
my $pwd     = cwd;

# Make sure install target is prepped.
unshift @PERL5LIB, $install, catdir($pwd, 'lib');
$PERL_MM_OPT = "INSTALL_BASE=$install";

# Prep the source tree
my $source = tempdir();

mkdir catdir($source, 'lib');
spew(catfile($source, 'lib', 'TestDist.pm'), "package TestDist;\n\$VERSION = '1.000';\n1;\n");

my $share = catdir($source, 'share');
my $dotdir = catdir($share, qw/dots .dotdir/);

mkpath($dotdir);
spew(catfile($dotdir, 'normalfile'), 'This is a normal file');
spew(catfile($dotdir, '.dotfile'), 'This is a dotfile');
spew(catfile($share, 'dots', '.dotfile'), 'This is a dotfile');
spew(catfile($share, 'normalfile'), 'This is a normal file');

spew(catfile($source, 'Makefile.PL'), <<'MAKEFILE');
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %Args = (
  ABSTRACT => "Test Module",
  DISTNAME => "TestDist",
  NAME => "TestDist",
  PREREQ_PM => {},
  sharedir => {
    dist => 'share',
  },
);

WriteMakefile(%Args);

MAKEFILE

chdir $source;
END { chdir $pwd }

sub run_ok {
    my (@command) = @_;
    my $desc = join ' ', @command;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($inh, $outh, $errh) = (undef, undef, gensym);
    my $pid = open3($inh, $outh, $errh, @command) or do {
        fail "Command $desc: $!";
        return;
    };
    close $inh;

    my $out = do { local $/; <$outh> };
    my $err = do { local $/; <$errh> };

    waitpid $pid, 0 or die 'Couldn\'t waitpid';
    return cmp_ok( $?, '==', 0, "Command $desc" ) || note explain { 'stdout' => $out, 'stderr' => $err, exit => $? }
}

# Testing happens here:
SKIP: {
    run_ok($^X, 'Makefile.PL');
    run_ok('make');
    run_ok('make', 'install');

	my $dir = catdir($install, qw/lib perl5 auto share dist TestDist share/);
	ok(-d $dir, 'Sharedir has been created');
	ok(-e catfile($dir, 'normalfile'), 'File in sharedir has been created');
    ok(-e catfile($dir, qw/dots .dotdir .dotfile/), 'A dotfile in a dotdir installed');
}

sub spew {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or die "Couldn't open $filename: $!";
	print $fh $content or die "Couldn't write to $filename: $!";
	close $fh or die "Couldn't close $filename: $!";
	return;
}
