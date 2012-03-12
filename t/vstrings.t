#!/usr/bin/perl -w

# This test tests for support for various forms of vstring versions in PREREQ_PM

# Magic for core
BEGIN {

    # Always run in t to unify behavor with core
    chdir 't' if -d 't';
}

# Use things from t/lib/
use lib './lib';
use strict;
use TieOut;
use MakeMaker::Test::Utils;

use ExtUtils::MakeMaker;
use Test::More;

sub capture_make {
    my ( $package, $version ) = @_ ;

    my $warnings = '';
    local $SIG{__WARN__} = sub {
        $warnings .= join '', @_;
    };

    local $ENV{PERL_CORE} = 0;

    WriteMakefile(
        NAME      => 'VString::Test',
        PREREQ_PM => { $package , $version }
    );

    return $warnings;

}

{

    ok( my $stdout = tie *STDOUT, 'TieOut' );

    my $out;

    ok( eval { $out=""; $out = capture_make( "Fake::DecimalString" => '1.2.3' ); 1 }, '3-part Decimal String doesn\'t fatal' );
    unlike ( $out , qr/isn't\s+numeric/i , '"1.2.3" parses as a vstring');

    ok( eval { $out=""; $out = capture_make( "Fake::VDecimalString" => 'v1.2.3' ); 1 }, '3-part V-Decimal String doesn\'t fatal' );
    unlike ( $out, qr/Unparsable\s+version/i , '"v1.2.3" parses as a vstring');

    ok( eval { $out=""; $out = capture_make (  "Fake::BareVString" => v1.2.3 ); 1 }, '3-part bare V-string doesn\'t fatal' );
    unlike( $out, qr/Unparsable\s+version/i, 'v1.2.3 parses as a vstring');

    ok( eval { $out=""; $out =  capture_make (  "Fake::VDecimalString" => 'v1.2' ); 1 }, '2-part v-decimal string doesn\'t fatal' );
    unlike( $out, qr/Unparsable\s+version/i, '"v1.2" parses as a vstring');

    ok( eval { $out=""; $out = capture_make (  "Fake::BareVString" => v1.2 ); 1 }, '2-part bare v-string doesn\'t fatal');
    unlike( $out, qr/Unparsable\s+version/i , 'v1.2 parses as a vstring');

}

done_testing();
