# Test problems in Makefile.PL's and hint files.

BEGIN {
    unshift @INC, 't/lib';
}
chdir 't';

use strict;
use Test::More;
use Config;
BEGIN {
  plan skip_all => 'Need perlio and perl 5.8+.'
    if $] < 5.008 or !$Config{useperlio};
  plan tests => 7;
}
use ExtUtils::MM;
use MakeMaker::Test::Setup::Unicode;
use MakeMaker::Test::Utils;
use TieOut;

my $MM = bless { DIR => ['.'] }, 'MM';

ok( setup_recurs(), 'setup' );
END {
    ok( chdir File::Spec->updir, 'chdir updir' );
    ok( teardown_recurs(), 'teardown' );
}

ok( chdir 'Problem-Module', "chdir'd to Problem-Module" ) ||
  diag("chdir failed: $!");

# Make sure when Makefile.PL's break, they issue a warning.
# Also make sure Makefile.PL's in subdirs still have '.' in @INC.
{
    my $stdout = tie *STDOUT, 'TieOut' or die;

    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = join '', @_ };
    $MM->eval_in_subdirs;
	is $warning, '', 'no warning';

    open my $json_fh, '<:utf8', 'MYMETA.json' or die $!;
    my $json = do { local $/; <$json_fh> };
    close $json_fh;

    require Encode;
    my $str = Encode::decode( 'utf8', "Danijel Tašov's" );
    like( $json, qr/$str/, 'utf8 abstract' );

    untie *STDOUT;
}

my $make = make_run();
run("$make");


open my $man_fh, '<:utf8', File::Spec->catfile(qw(blib man1 probscript.1)) or die $!;
my $man = do { local $/; <$man_fh> };
close $man_fh;

require Encode;
my $str = Encode::decode( 'utf8', "文档" );
like( $man, qr/$str/, 'utf8 man-snippet' );
