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
use Test::More tests => 7;
use File::Spec;

my $TB = Test::More->builder;

BEGIN { use_ok('ExtUtils::MM') }

my $mm = bless { NAME => "Foo" }, 'MM';
isa_ok($mm, 'ExtUtils::MakeMaker');
isa_ok($mm, 'ExtUtils::MM_Any');


sub try_oneliner {
    my($code, $switches, $expect, $name) = @_;
    my $cmd = $mm->perl_oneliner($code, $switches);
    $cmd =~ s{\$\(PERLRUN\)}{$^X};

    # VMS likes to put newlines at the end of commands if there isn't
    # one already.
    $expect =~ s/([^\n])\z/$1\n/ if $^O eq 'VMS';

    $TB->is_eq(`$cmd`, $expect, $name) || $TB->diag("oneliner:\n$cmd");
        
}

# Lets see how it deals with quotes.
try_oneliner(q{print "foo'o", ' bar"ar'}, [],  q{foo'o bar"ar},  'quotes');

# How about dollar signs?
try_oneliner(q{$PATH = 'foo'; print $PATH},[], q{foo},   'dollar signs' );

# switches?
try_oneliner(q{print 'foo'}, ['-l'],           "foo\n",       'switches' );

# newlines?
try_oneliner(<<CODE, [],    "foobar",                   'newlines' );
print 'foo';
print 'bar';
CODE


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
