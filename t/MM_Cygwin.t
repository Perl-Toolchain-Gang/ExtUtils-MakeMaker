#!/usr/bin/perl

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use Test::More;

BEGIN {
	if ($^O =~ /cygwin/i) {
		plan tests => 11;
	} else {
		plan skip_all => "This is not cygwin";
	}
}

use Config;
use File::Spec;
use ExtUtils::MM;

use_ok( 'ExtUtils::MM_Cygwin' );

# test canonpath
my $path = File::Spec->canonpath('/a/../../c');
is( MM->canonpath('/a/../../c'), $path,
	'canonpath() method should work just like the one in File::Spec' );

# test cflags, with the fake package below
my $args = bless({
	CFLAGS	=> 'fakeflags',
	CCFLAGS	=> '',
}, MM);

# with CFLAGS set, it should be returned
is( $args->cflags(), 'fakeflags',
	'cflags() should return CFLAGS member data, if set' );

delete $args->{CFLAGS};

# ExtUtils::MM_Cygwin::cflags() calls this, fake the output
{
    local $SIG{__WARN__} = sub { 
        warn @_ unless $_[0] =~ /^Subroutine .* redefined/;
    };
    *ExtUtils::MM_Unix::cflags = sub { return $_[1] };
}

# respects the config setting, should ignore whitespace around equal sign
my $ccflags = $Config{useshrplib} eq 'true' ? ' -DUSEIMPORTLIB' : '';
{
    local $args->{NEEDS_LINKING} = 1;
    $args->cflags(<<FLAGS);
OPTIMIZE = opt
PERLTYPE  =pt
FLAGS
}

like( $args->{CFLAGS}, qr/OPTIMIZE = opt/, '... should set OPTIMIZE' );
like( $args->{CFLAGS}, qr/PERLTYPE = pt/, '... should set PERLTYPE' );
like( $args->{CFLAGS}, qr/CCFLAGS = $ccflags/, '... should set CCFLAGS' );

# test manifypods
$args = bless({
	NOECHO => 'noecho',
	MAN3PODS => {},
	MAN1PODS => {},
    MAKEFILE => 'Makefile',
}, 'MM');
unlike( $args->manifypods(), qr/foo/,
	'manifypods() should return without PODS values set' );

$args->{MAN3PODS} = { foo => 'foo.1' };
my $res = $args->manifypods();
like( $res, qr/pure_all.*foo.*foo.1/s, '... should add MAN3PODS targets' );


SKIP: {
    skip "Only relevent in the core", 2 unless $ENV{PERL_CORE};
    $args->{PERL_SRC} = File::Spec->updir;
    $args->{MAN1PODS} = { bar => 1 };
    my $out = tie *STDOUT, 'FakeOut';
    $res = $args->manifypods();
    is( $$out, '', '... should not warn if PERL_SRC provided' );
    like( $res, qr/bar \\\n\t1 \\\n\tfoo/,
          '... should join MAN1PODS and MAN3PODS');
}


# init_linker
{
    my $libperl = $Config{libperl} || 'libperl.a';
    $libperl =~ s/\.a/.dll.a/ if $] >= 5.007;
    $libperl "\$(PERL_INC)/$libperl";

    my $export  = '$(BASEEXT).def';
    my $after   = '';
    $MM->init_linker;

    is( $MM->{PERL_ARCHIVE},        $libperl,   'PERL_ARCHIVE' );
    is( $MM->{PERL_ARCHIVE_AFTER},  $after,     'PERL_ARCHIVE_AFTER' );
    is( $MM->{EXPORT_LIST},         $export,    'EXPORT_LIST' );
}



package FakeOut;

sub TIEHANDLE {
	bless(\(my $scalar), $_[0]);
}

sub PRINT {
	my $self = shift;
	$$self .= shift;
}
