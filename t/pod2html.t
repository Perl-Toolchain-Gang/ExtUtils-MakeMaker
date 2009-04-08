#!/usr/bin/perl -w

# Test our emulation of pod2html.

use strict;

use Test::More 'no_plan';

use ExtUtils::Command::MM;
use File::Path;

ok mkdir "pod2html_tmp" or diag $!;
END { chdir ".."; rmtree "pod2html_tmp" }
ok chdir "pod2html_tmp" or diag $!;


# No arguments
{
    ok !eval {
        pod2html();
    };
    like $@, qr/^Need to specify both --infile and --outfile/;
}


# A really basic test of pod2html's generation.
{
    ok open my $fh, ">", "temp.pod" or diag $!;
    print $fh <<POD;
=pod

=head1 NAME

Whatever

=head1 DESCRIPTION

This is some pod

=cut

POD

    close $fh;

    ok !-d "path";

    pod2html(
        "--infile=temp.pod",
        "--outfile=path/temp.html",
    );

    ok -d "path", "pod2html() made the path for outfile";

    open my $html_fh, "<", "path/temp.html" or diag $!;
    my $html = join '', <$html_fh>;
    like $html, qr/<HTML/i,             "Looks like HTML";
    like $html, qr/This is some pod/,   "Contains the documentation";
}
