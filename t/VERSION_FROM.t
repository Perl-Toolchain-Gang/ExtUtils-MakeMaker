BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;
use Test::More tests => 1;
use ExtUtils::MakeMaker;
use TieOut;

open(MPL, ">Version.pm") || die $!;
print MPL "\$VERSION = 0\n";
close MPL;
END { unlink 'Version.pm' }

my $stdout = tie *STDOUT, 'TieOut' or die;
my $mm = WriteMakefile(
    NAME         => 'Version',
    VERSION_FROM => 'Version.pm'
);

is( $mm->{VERSION}, 0, 'VERSION_FROM when $VERSION = 0' );
