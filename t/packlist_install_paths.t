#!/usr/bin/perl

use strict;
use warnings;

use Config;
use Cwd qw(abs_path getcwd);
use ExtUtils::MakeMaker ();
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $make = $Config{make};

plan skip_all => 'make unavailable'
  if !$make;

my $temp = tempdir( CLEANUP => 1 );
my $base = File::Spec->catdir( $temp, 'install-root' );
my $lib  = abs_path('lib');
my $perl = $^X;
my $cwd  = getcwd();

########################################################################
sub get_packlists {
########################################################################
  my @packlists;

  find(
    sub {
      if ( $_ eq '.packlist' && -f $File::Find::name ) {
        push @packlists, $File::Find::name;
      }
    },
    $base,
  );

  return @packlists;
}

########################################################################
sub has_legacy_script {
########################################################################
  my ($packlist) = @_;

  open my $in, '<', $packlist
    or die "$packlist: $!";

  my $contents = do { local $/; <$in> };

  close $in or die "$packlist: $!";

  return $contents =~ /legacy-probe/;
}

########################################################################
sub install_version {
########################################################################
  my ( $version, $with_script ) = @_;

  my $dir = File::Spec->catdir( $temp, "source-$version" );
  make_path( File::Spec->catdir( $dir, 'lib', 'Packlist' ) );

  my $module = File::Spec->catfile( $dir, 'lib', 'Packlist', 'Probe.pm' );

  open my $pm, '>', $module
    or die "$module: $!";

  print {$pm} "package Packlist::Probe; our \$VERSION = '$version'; 1;\n";

  close $pm or die "$module: $!";

  if ($with_script) {
    my $bin = File::Spec->catdir( $dir, 'bin' );
    make_path($bin);
    my $script = File::Spec->catfile( $bin, 'legacy-probe' );

    open my $exe, '>', $script
      or die "$script: $!";

    print {$exe} "#!$perl\nprint qq{legacy};\n";

    close $exe
      or die "$script: $!";

    chmod 0755, $script;
  }

  my $makefile_pl = File::Spec->catfile( $dir, 'Makefile.PL' );

  open my $mf, '>', $makefile_pl
    or die "$makefile_pl: $!";

  print {$mf} "use ExtUtils::MakeMaker; WriteMakefile(NAME => 'Packlist::Probe', VERSION => '$version',";

  if ($with_script) {
    print {$mf} " EXE_FILES => ['bin/legacy-probe'],";
  }

  print {$mf} " INSTALLDIRS => 'site');\n";

  close $mf
    or die "$makefile_pl: $!";

  chdir $dir
    or die "chdir $dir: $!";

  # perl Makefile.PL INSTALL_BASE=...
  my $generated = system $perl, "-I$lib", 'Makefile.PL', "INSTALL_BASE=$base";

  # make install
  my $installed = $generated == 0 ? system( $make, 'install' ) : $generated;

  chdir $cwd
    or die "chdir $cwd: $!";

  return $installed == 0;
}

my $packlist;

ok( install_version( '0.01', 1 ), 'initial installation with executable succeeded' );

my @packlists = get_packlists();

is( scalar @packlists, 1, 'initial installation created one packlist' );

$packlist = $packlists[0];

ok( has_legacy_script( $packlists[0] ), 'first packlist includes the executable' );

# Version 2 omits the executable
ok( install_version( '0.02', 0 ), 'second installation without executable succeeded' );

ok( has_legacy_script($packlist), 'reinstall retains obsolete executable in packlist' );

done_testing;
