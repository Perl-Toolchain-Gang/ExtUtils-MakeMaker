#!/usr/bin/perl -w

# This script tests ExtUtils::MakeMaker::supports_param().

use strict;
use Test::More;

# We don’t need to test all parameters; just enough to verify that the
# mechanism is working.  This list is somewhat random, but it works.

my @supported = qw(
 ABSTRACT_FROM
 AUTHOR
 BUILD_REQUIRES
 clean
 dist
 DISTNAME
 DISTVNAME
 LIBS
 MAN3PODS
 META_MERGE
 MIN_PERL_VERSION
 NAME
 PL_FILES
 PREREQ_PM
 VERSION
 VERSION_FROM
);

my @unsupported = qw(
 WIBBLE
 wump
);

plan tests => 2*(@supported+@unsupported);

use ExtUtils::MakeMaker 'supports_param';

for (@supported) {
    ok supports_param($_), "EUMM supports param '$_' (exported func)";
    ok ExtUtils::MakeMaker::supports_param($_), "EUMM supports param '$_'";
}
for (@unsupported) {
    ok !supports_param($_),
        "EUMM does not support param '$_' (exported func)";
    ok !ExtUtils::MakeMaker::supports_param($_),
        "EUMM does not support param '$_'";
}
