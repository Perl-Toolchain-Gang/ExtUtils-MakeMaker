#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        unshift @INC, '../lib';
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use strict;
use Test::More tests => 5;

BEGIN {
    use_ok( 'ExtUtils::Liblist' );
}

{
    my @warn;
    local $SIG{__WARN__} = sub {push @warn, [@_]};

    my @out = ExtUtils::Liblist->ext('-ln0tt43r3_perl');
    is( @out, 4, 'enough output' );
    unlike( $out[2], qr/-ln0tt43r3_perl/, 'bogus library not added' );
    is( @warn, 1, 'had warning');
    like($warn[0][0],
         qr/\QNote (probably harmless): No library found for -ln0tt43r3_perl/,
         'expected warning');
}
