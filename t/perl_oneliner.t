#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

chdir 't';

use MakeMaker::Test::Utils;
use Test::More tests => 5;
use File::Spec;

BEGIN { use_ok('ExtUtils::MM') }

my $mm = bless { NAME => "Foo" }, 'MM';
isa_ok($mm, 'ExtUtils::MakeMaker');
isa_ok($mm, 'ExtUtils::MM_Any');


my $command;

# Lets see how it deals with quotes.
$command = $mm->perl_oneliner(q{print "foo'o", ' bar"ar'});
$command =~ s{\$\(PERLRUN\)}{$^X};
is(`$command`, q{foo'o bar"ar},  'quotes');


# How about dollar signs?
$command = $mm->perl_oneliner(q{$PATH = 'foo';  print $PATH});
$command =~ s{\$\(PERLRUN\)}{$^X};
is(`$command`, q{foo},           'dollar signs' );


# I know this doesn't work ATM.
# Spaces in the path to perl?
# SKIP: {
#     my $trick_perl = File::Spec->catfile(File::Spec->curdir, 'p e r l');
#     my $symlink = eval { symlink which_perl(), $trick_perl };
#     skip "symlink not available", 1 if $@ =~ /unimplemented/ or
#                                        !$symlink;

#     $command = $mm->perl_oneliner(q{print "foo"});
#     $command =~ s{\$\(PERLRUN\)}{$trick_perl};
#     is(`$command`, q{foo},           'spaces in path to perl' );
#     END { unlink 'p erl'; }
# }
