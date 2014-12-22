package MakeMaker::Test::Setup::XS;

@ISA = qw(Exporter);
require Exporter;
@EXPORT = qw(run_tests list_dynamic);

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

sub list_dynamic {
  (
    [ 'basic', '', '' ],
    [ 'bscode', '', '' ],
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
    is( $?, 0, "$test_cmd exited normally" ) || diag $test_out;
  }

  chdir File::Spec->updir or die;
  ok rmtree($dir), "teardown $dir";
}

1;
