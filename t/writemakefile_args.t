#!/usr/bin/perl -w

# This is a test of the verification of the arguments to
# WriteMakefile.

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
use Test::More tests => 6;

use TieOut;
use MakeMaker::Test::Utils;

use ExtUtils::MakeMaker;

chdir 't';

perl_lib();

ok( chdir 'Big-Dummy', "chdir'd to Big-Dummy" ) ||
  diag("chdir failed: $!");

{
    ok( my $stdout = tie *STDOUT, 'TieOut' );
    my $warnings = '';
    local $SIG{__WARN__} = sub {
        $warnings .= join '', @_;
    };

    my $mm = WriteMakefile(
        NAME            => 'Big::Dummy',
        VERSION_FROM    => 'lib/Big/Dummy.pm',
        MAN3PODS        => ' ', # common mistake
    );

    is( $warnings, <<VERIFY );
WARNING: MAN3PODS takes a hash reference not a string/number.
         Please inform the author.
VERIFY
    is_deeply( $mm->{MAN3PODS}, {}, 'Wrong argument type corrected' );

    $warnings = '';
    $mm = WriteMakefile(
        NAME            => 'Big::Dummy',
        VERSION_FROM    => 'lib/Big/Dummy.pm',
        AUTHOR          => sub {},
    );
    
    is( $warnings, <<VERIFY );
WARNING: AUTHOR takes a string/number not a code reference.
         Please inform the author.
VERIFY

    is_deeply( $mm->{AUTHOR}, '' );
}
