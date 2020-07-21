#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

chdir 't';

use Config;
use MakeMaker::Test::Utils qw(makefile_name make_run run which_perl);
use Test::More;
use File::Temp qw[tempdir];
use File::Spec;
use Cwd;

my $TB   = Test::More->builder;
my $perl = which_perl;

BEGIN { use_ok('ExtUtils::MM') }

my $mm = bless { NAME => "Foo", MAKE => $Config{make} }, 'MM';
isa_ok( $mm, 'ExtUtils::MakeMaker' );
isa_ok( $mm, 'ExtUtils::MM_Any' );

my $make = make_run();

my $tmpdir = tempdir( CLEANUP => 1 );

my $cwd = getcwd;
END { chdir $cwd if defined $cwd }    # so File::Temp can cleanup

# run all these test from a temporary directory
chdir($tmpdir) or die "Fail to change to tmp directory: $!";

# Lets see how it deals with quotes.
try_oneliner( q{print "foo'o", ' bar"ar'}, [], q{foo'o bar"ar}, 'quotes' );

# How about dollar signs?
try_oneliner( q{my $PATH = 'foo'; print $PATH}, [], q{foo}, 'dollar signs' );
try_oneliner( q{my %h = (1, 2); print $h{1}},   [], q{2},   '%h and $h' );

# switches?
try_oneliner( q{print 'foo'}, ['-l'], "foo\n", 'switches' );

# some DOS-specific things
try_oneliner( q{print " \" "},   [], q{ " },   'single quote' );
try_oneliner( q{print " < \" "}, [], q{ < " }, 'bracket, then quote' );
try_oneliner( q{print " \" < "}, [], q{ " < }, 'quote, then bracket' );
try_oneliner(
    q{print " < \"\" < \" < \" < "}, [], q{ < "" < " < " < },
    'quotes and brackets mixed'
);
try_oneliner(
    q{print " < \" | \" < | \" < \" < "}, [],
    q{ < " | " < | " < " < }, 'brackets, pipes and quotes'
);

# some examples from http://www.autohotkey.net/~deleyd/parameters/parameters.htm#CPP
try_oneliner( q{print q[ &<>^|()@ ! ]}, [], q{ &<>^|()@ ! }, 'example 8.1' );
try_oneliner(
    q{print q[ &<>^|@()!"&<>^|@()! ]}, [],
    q{ &<>^|@()!"&<>^|@()! }, 'example 8.2'
);
try_oneliner(
    q{print q[ "&<>^|@() !"&<>^|@() !" ]}, [],
    q{ "&<>^|@() !"&<>^|@() !" }, 'example 8.3'
);
try_oneliner(
    q{print q[ "C:\TEST A\" ]}, [], q{ "C:\TEST A\" },
    'example 8.4'
);
try_oneliner(
    q{print q[ "C:\TEST %&^ A\" ]}, [], q{ "C:\TEST %&^ A\" },
    'example 8.5'
);

# XXX gotta rethink the newline test.  The Makefile does newline
# escaping, then the shell.

done_testing;
exit;

sub try_oneliner {
    my ( $code, $switches, $expect, $name ) = @_;
    my $cmd = $mm->oneliner( $code, $switches );
    $cmd =~ s{\$\(ABSPERLRUN\)}{$perl};

    # VMS likes to put newlines at the end of commands if there isn't
    # one already.
    $expect =~ s/([^\n])\z/$1\n/ if $^O eq 'VMS';

    my $Makefile = makefile_name();

    my $content = Makefile_template($cmd);
    write_file( $Makefile, $content );

    my $output = run(qq{$make -s all});

    my $ok = $TB->is_eq( $output, $expect, $name )
        || $TB->diag("$Makefile:\n$content");

    return $ok;
}

sub Makefile_template {
    my ($RUN) = @_;
    my $NOECHO = '@';

    return <<"MAKEFILE";
all:
	${NOECHO} ${RUN}
MAKEFILE
}

sub write_file {
    my ( $f, $content ) = @_;

    open( my $fh, '>', $f ) or die $!;
    print {$fh} $content or die $!;
    close $fh;

    return;
}
