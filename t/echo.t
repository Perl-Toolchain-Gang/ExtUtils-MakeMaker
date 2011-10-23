#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

use strict;
use warnings;

use Carp;
use Config;
use ExtUtils::MM;
use MakeMaker::Test::Utils;
use File::Temp;
use Cwd 'abs_path';

my $Is_VMS   = $^O eq 'VMS';
my $Is_Win32 = $^O eq 'MSWin32';

use Test::More;

# Setup
my $cwd  = abs_path;
my $perl = which_perl;
my $make = make_run();
my $mm = bless { NAME => "Foo", MAKE => $Config{make} }, "MM";
$mm->init_tools;  # need ECHO


# Testing functions
sub test_for_echo {
    my($args, $want, $name) = @_;
    my $output_file = $args->[1];

    note "Testing $name";

    my $dir = File::Temp->newdir();
    chdir $dir;
    note "Temp dir: $dir";

    {
        open my $makefh, ">", "Makefile" or croak "Can't open Makefile: $!";
        print $makefh "ECHO=$mm->{ECHO}\n\n";
        print $makefh "all:\n";
        print $makefh map { "\t".$_ } $mm->echo(@$args);
    }

    ok run($make), "make: $name";

    ok -e $output_file, "$output_file exists";
    open my $fh, "<", $output_file or croak "Can't open $output_file: $!";
    is join("", <$fh>), $want, "contents";

    chdir $cwd;
}


# Tests begin
test_for_echo(
    ["Foo", "bar.txt"], "Foo\n", "simple echo"
);


done_testing;
