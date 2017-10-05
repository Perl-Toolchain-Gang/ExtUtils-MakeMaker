#!/usr/bin/perl -w

use strict;
use warnings;
use Config;
BEGIN {
    chdir 't' or die "chdir(t): $!\n";
    unshift @INC, 'lib/';
}
use MakeMaker::Test::Utils;
use MakeMaker::Test::Setup::XS;
use Test::More;

plan skip_all => "ExtUtils::CBuilder not installed or no C++ compiler"
  unless have_cplusplus();
plan skip_all => 'Dynaloading not enabled' if $Config{usedl} ne 'define';
plan skip_all => 'No ExtUtils::CppGuess'
  unless eval { require ExtUtils::CppGuess };
my @tests = list_cpp();
plan skip_all => "No tests" unless @tests;
plan tests => 6 * @tests;
my $perl = which_perl();
perl_lib;
$| = 1;
run_tests($perl, @$_) for @tests;
