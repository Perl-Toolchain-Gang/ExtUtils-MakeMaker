package MakeMaker::Test::Setup::XS;

@ISA = qw(Exporter);
require Exporter;
@EXPORT = qw(run_tests list_dynamic list_static);

use strict;
use File::Path;
use MakeMaker::Test::Utils;
use Config;
use Carp qw(croak);
use Test::More;
use File::Spec;

use File::Temp qw[tempdir];
use Cwd;
use ExtUtils::MM;
# this is to avoid MM->new overwriting _eumm in top dir
my $tempdir = tempdir(DIR => getcwd, CLEANUP => 1);
chdir $tempdir;
my $typemap = 'type map';
$typemap =~ s/ //g unless MM->new({NAME=>'name', NORECURS=>1})->can_dep_space;
chdir File::Spec->updir;

my $PM_TEST = <<'END';
package XS::Test;
require Exporter;
require DynaLoader;
$VERSION = 1.01;
@ISA    = qw(Exporter DynaLoader);
@EXPORT = qw(is_even);
bootstrap XS::Test $VERSION;
1;
END

my $XS_TEST = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
MODULE = XS::Test       PACKAGE = XS::Test
PROTOTYPES: DISABLE
int
is_even(input)
       int     input
   CODE:
       RETVAL = (input % 2 == 0);
   OUTPUT:
       RETVAL
END

my $T_TEST = <<'END';
#!/usr/bin/perl -w
use Test::More tests => 3;
use_ok "XS::Test";
ok !is_even(1);
ok is_even(2);
END

my $MAKEFILEPL = <<'END';
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'XS::%s',
  VERSION_FROM  => '%s',
  TYPEMAPS      => [ %s ],
  PERL          => "$^X -w",
  %s
);
END

my $BS_TEST = '$DynaLoader::bscode = q(warn "BIG NOISE";)';

my $T_BOOTSTRAP = <<'EOF';
use Test::More tests => 1;
my $w = '';
$SIG{__WARN__} = sub { $w .= join '', @_; };
require XS::Test;
like $w, qr/NOISE/;
EOF

my $PM_OTHER = <<'END';
package XS::Other;
require Exporter;
require DynaLoader;
$VERSION = 1.20;
@ISA    = qw(Exporter DynaLoader);
@EXPORT = qw(is_odd);
bootstrap XS::Other $VERSION;
1;
END

my $XS_OTHER = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
MODULE = XS::Other       PACKAGE = XS::Other
PROTOTYPES: DISABLE
int
is_odd(input)
       int     input
   CODE:
       RETVAL = (INVAR % 2 == 1);
   OUTPUT:
       RETVAL
END

my $T_OTHER = <<'END';
#!/usr/bin/perl -w
use Test::More tests => 3;
use_ok "XS::Other";
ok is_odd(1);
ok !is_odd(2);
END

my %Files = (
  'lib/XS/Test.pm' => $PM_TEST,
  $typemap => '',
  'Test.xs' => $XS_TEST,
  't/is_even.t' => $T_TEST,
  'Makefile.PL' => sprintf($MAKEFILEPL, 'Test', 'lib/XS/Test.pm', qq{'$typemap'}, ''),
);

my %label2files = (basic => \%Files);

$label2files{bscode} = +{
  %{ $label2files{'basic'} }, # make copy
  'Test_BS' => $BS_TEST,
  't/bs.t' => $T_BOOTSTRAP,
};
delete $label2files{bscode}->{'t/is_even.t'};

$label2files{static} = +{
  %{ $label2files{'basic'} }, # make copy
  'Makefile.PL' => sprintf(
    $MAKEFILEPL, 'Test', 'lib/XS/Test.pm', qq{'$typemap'},
    q{LINKTYPE => 'static'},
  ),
};

$label2files{subdirs} = +{
  %{ $label2files{'basic'} }, # make copy
  'Makefile.PL' => sprintf(
    $MAKEFILEPL, 'Test', 'Test.pm', qq{'$typemap'},
    q{DEFINE => '-DINVAR=input',},
  ),
  'Other/Makefile.PL' => sprintf($MAKEFILEPL, 'Other', 'Other.pm', qq{}, ''),
  'Other/Other.pm' => $PM_OTHER,
  'Other/Other.xs' => $XS_OTHER,
  't/is_odd.t' => $T_OTHER,
};
virtual_rename('subdirs', 'lib/XS/Test.pm', 'Test.pm');

$label2files{subdirsstatic} = +{
  %{ $label2files{'subdirs'} }, # make copy
  'Makefile.PL' => sprintf(
    $MAKEFILEPL, 'Test', 'Test.pm', qq{'$typemap'},
    q{DEFINE => '-DINVAR=input', LINKTYPE => 'static',},
  ),
};

my $XS_MULTI = $XS_OTHER;
# check compiling from top dir still can include local
$XS_MULTI =~ s:(#include "XSUB.h"):$1\n#include "header.h":;
$label2files{multi} = +{
  %{ $label2files{'basic'} }, # make copy
  'Makefile.PL' => sprintf(
    $MAKEFILEPL, 'Test', 'lib/XS/Test.pm', qq{'lib/XS/$typemap'},
    q{XSMULTI => 1,},
  ),
  'lib/XS/Other.pm' => $PM_OTHER,
  'lib/XS/Other.xs' => $XS_MULTI,
  't/is_odd.t' => $T_OTHER,
  'lib/XS/header.h' => "#define INVAR input\n",
};
virtual_rename('multi', $typemap, "lib/XS/$typemap");
virtual_rename('multi', 'Test.xs', 'lib/XS/Test.xs');

$label2files{bscodemulti} = +{
  %{ $label2files{'multi'} }, # make copy
  'lib/XS/Test_BS' => $BS_TEST,
  't/bs.t' => $T_BOOTSTRAP,
};
delete $label2files{bscodemulti}->{'t/is_even.t'};
delete $label2files{bscodemulti}->{'t/is_odd.t'};

$label2files{staticmulti} = +{
  %{ $label2files{'multi'} }, # make copy
  'Makefile.PL' => sprintf(
    $MAKEFILEPL, 'Test', 'lib/XS/Test.pm', qq{'$typemap'},
    q{LINKTYPE => 'static', XSMULTI => 1,},
  ),
};

$label2files{xsbuild} = +{
  %{ $label2files{'multi'} }, # make copy
  'Makefile.PL' => sprintf(
    $MAKEFILEPL, 'Test', 'lib/XS/Test.pm', qq{'$typemap'},
    q{
      XSMULTI => 1,
      XSBUILD => {
        xs => {
          'lib/XS/Other' => {
            DEFINE => '-DINVAR=input',
            OBJECT => 'lib/XS/Other$(OBJ_EXT) lib/XS/plus1$(OBJ_EXT)'
          }
        },
      },
    },
  ),
  'lib/XS/Other.xs' => $XS_OTHER . <<EOF,
\nint
plus1(input)
       int     input
   CODE:
       RETVAL = plus1(INVAR);
   OUTPUT:
       RETVAL
EOF
  'lib/XS/plus1.c' => 'int plus1(i) int i; { return i + 1; }',
  't/is_odd.t' => <<'END',
#!/usr/bin/perl -w
use Test::More tests => 4;
use_ok "XS::Other";
ok is_odd(1);
ok !is_odd(2);
is XS::Other::plus1(3), 4;
END
};

sub virtual_rename {
  my ($label, $oldfile, $newfile) = @_;
  $label2files{$label}->{$newfile} = delete $label2files{$label}->{$oldfile};
}

sub setup_xs {
  my ($label, $sublabel) = @_;
  croak "Must supply label" unless defined $label;
  my $files = $label2files{$label};
  croak "Must supply valid label" unless defined $files;
  croak "Must supply sublabel" unless defined $sublabel;
  my $prefix = "XS-Test$label$sublabel";
  hash2files($prefix, $files);
  return $prefix;
}

sub list_static {
  (
    ( !$Config{usedl} ? [ 'basic', '', '' ] : ()), # still needs testing on static perl
    [ 'static', '', '' ],
    [ 'basic', ' static', '_static' ],
    [ 'multi', ' static', '_static' ],
    [ 'subdirs', ' LINKTYPE=static', ' LINKTYPE=static' ],
    [ 'subdirsstatic', '', '' ],
    [ 'staticmulti', '', '' ],
  );
}

sub list_dynamic {
  (
    [ 'basic', '', '' ],
    $^O ne 'MSWin32' ? (
        [ 'bscode', '', '' ],
        [ 'bscodemulti', '', '' ],
    ) : (), # DynaLoader different
    [ 'subdirs', '', '' ],
    [ 'subdirsstatic', ' LINKTYPE=dynamic', ' LINKTYPE=dynamic' ],
    [ 'subdirsstatic', ' dynamic', '_dynamic' ],
    [ 'multi', '', '' ],
    [ 'staticmulti', ' LINKTYPE=dynamic', ' LINKTYPE=dynamic' ],
    [ 'staticmulti', ' dynamic', '_dynamic' ],
    [ 'xsbuild', '', '' ],
  );
}

sub run_tests {
  my ($perl, $label, $add_target, $add_testtarget) = @_;
  my $sublabel = $add_target;
  $sublabel =~ s#[\s=]##g;
  ok( my $dir = setup_xs($label, $sublabel), "setup $label$sublabel" );

  ok( chdir($dir), "chdir'd to $dir" ) || diag("chdir failed: $!");

  my @mpl_out = run(qq{$perl Makefile.PL});
  SKIP: {
    unless (cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' )) {
      diag(@mpl_out);
      skip 'perl Makefile.PL failed', 2;
    }

    my $make = make_run();
    my $make_cmd = $make . (defined $add_target ? $add_target : '');
    my $make_out = run($make_cmd);
    unless (is( $?, 0, "$make_cmd exited normally" )) {
        diag $make_out;
        skip 'Make failed - skipping test', 1;
    }

    my $test_cmd = "$make test" . (defined $add_testtarget ? $add_testtarget : '');
    my $test_out = run($test_cmd);
    is( $?, 0, "$test_cmd exited normally" ) || diag "$make_out\n$test_out";
  }

  chdir File::Spec->updir or die;
  ok rmtree($dir), "teardown $dir";
}

1;
