#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

use Test::More 'no_plan';

sub test_abstract {
    my($code, $package, $want, $name) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $file = "t/abstract.tmp";
    {
        open my $fh, ">", $file or die "Can't open $file";
        print $fh $code;
        close $fh;
    }

    # Hack up a minimal MakeMaker object.
    my $mm = bless { DISTNAME => $package }, "MM";
    my $have = $mm->parse_abstract($file);

    my $ok = is( $have, $want, $name );

    # Clean up the temp file, VMS style
    1 while unlink $file;

    return $ok;
}


test_abstract(<<END, "Stuff and things");
=head1 NAME

Foo - Stuff and things
END
