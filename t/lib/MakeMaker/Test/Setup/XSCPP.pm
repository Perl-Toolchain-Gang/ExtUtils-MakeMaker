package MakeMaker::Test::Setup::XSCPP;

@ISA = qw(Exporter);
require Exporter;
@EXPORT = qw(setup_xs teardown_xs);

use strict;
use File::Path;
use File::Basename;
use MakeMaker::Test::Utils;

my $Is_VMS = $^O eq 'VMS';

my %Files = (
             'XSCPP-Test/lib/XSCPP/Test.pm'     => <<'END',
package XSCPP::Test;

require Exporter;
require DynaLoader;

$VERSION = 1.01;
@ISA    = qw(Exporter DynaLoader);
@EXPORT = qw(is_even);

bootstrap XSCPP::Test $VERSION;

1;
END

             'XSCPP-Test/Makefile.PL'          => <<'END',
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XSCPP::Test',
    VERSION_FROM  => 'lib/XSCPP/Test.pm',
    XSTARGET_EXT  => '.cpp',
    LIBS          => ['-lstdc++'],
);
END

             'XSCPP-Test/Test.xs'              => <<'END',
extern "C" {
#include "EXTERN.h"
#include "perl.h"
}

#include "XSUB.h"

class CPPTest {
    public:
        CPPTest() { }
        ~CPPTest() { }
        int is_even(int num) { return (num % 2) == 0; }
};

MODULE = XSCPP::Test       PACKAGE = XSCPP::Test

PROTOTYPES: DISABLE

CPPTest*
CPPTest::new();

int
CPPTest::is_even(int input);

void
CPPTest::DESTROY();

END

             'XSCPP-Test/typemap'              => <<'END',
TYPEMAP
CPPTest *   O_OBJECT

OUTPUT

O_OBJECT
    sv_setref_pv( $arg, CLASS, (void*)$var );

INPUT

O_OBJECT
    if( sv_isobject($arg) && (SvTYPE(SvRV($arg)) == SVt_PVMG) )
        $var = ($type)SvIV((SV*)SvRV( $arg ));
    else{
        warn( \"${Package}::$func_name() -- $var is not a blessed SV reference\" );
        XSRETURN_UNDEF;
    }

END

             'XSCPP-Test/t/is_even.t'          => <<'END',
#!/usr/bin/perl -w

use Test::More tests => 3;

use_ok "XSCPP::Test";
my $o = XSCPP::Test->new;
ok !$o->is_even(1);
ok $o->is_even(2);
END
            );


sub setup_xs {
    setup_mm_test_root();
    chdir 'MM_TEST_ROOT:[t]' if $Is_VMS;

    while(my($file, $text) = each %Files) {
        # Convert to a relative, native file path.
        $file = File::Spec->catfile(File::Spec->curdir, split m{\/}, $file);

        my $dir = dirname($file);
        mkpath $dir;
        open(FILE, ">$file") || die "Can't create $file: $!";
        print FILE $text;
        close FILE;
    }

    return 1;
}

sub teardown_xs { 
    foreach my $file (keys %Files) {
        my $dir = dirname($file);
        if( -e $dir ) {
            rmtree($dir) || return;
        }
    }
    return 1;
}

1;
