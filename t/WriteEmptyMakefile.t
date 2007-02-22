#!/usr/bin/perl -w

# This is a test of WriteEmptyMakefile.

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
use Test::More 'no_plan';

use ExtUtils::MakeMaker qw(WriteEmptyMakefile);

can_ok __PACKAGE__, 'WriteEmptyMakefile';

eval { WriteEmptyMakefile("something"); };
like $@, qr/Need an even number of args/;

