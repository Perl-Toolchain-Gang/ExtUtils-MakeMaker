# This is a test of WriteEmptyMakefile.

BEGIN {
    unshift @INC, 't/lib';
}

use File::Temp qw[tempdir];
my $tmpdir = tempdir( DIR => 't', CLEANUP => 1 );
use Cwd; my $cwd = getcwd; END { chdir $cwd } # so File::Temp can cleanup
chdir $tmpdir;

use strict;
use warnings;
use Test::More tests => 6;

use ExtUtils::MakeMaker qw(WriteEmptyMakefile);
use TieOut;

can_ok __PACKAGE__, 'WriteEmptyMakefile';

eval { WriteEmptyMakefile("something"); };
like $@, qr/Need an even number of args/, 'correct exception';

{
    ok( (my $stdout = tie *STDOUT, 'TieOut' ), 'tie stdout');

    ok !-e 'wibble', 'no wibble';
    END { 1 while unlink 'wibble' }

    WriteEmptyMakefile(
        NAME            => "Foo",
        FIRST_MAKEFILE  => "wibble",
    );
    ok -e 'wibble', 'yes wibble';
    ok !-d 'blib/_eumm', 'no _eumm lying around';
}
