#!/usr/bin/perl -w

# Test our simulation of pod2man

use strict;
use lib 't/lib';

use ExtUtils::Command::MM;

use Test::More tests => 1;

# The argument to perm_rw was optional.
# [rt.cpan.org 35190]
{
    my $warnings;
    local $SIG{__WARN__} = sub {
        $warnings .= join '', @_;
    };

    pod2man("--perm_rw");

    like $warnings, qr/^Option perm_rw requires an argument/;
};
