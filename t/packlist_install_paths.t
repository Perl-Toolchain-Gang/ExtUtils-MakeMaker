#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use ExtUtils::MakeMaker ();

plan skip_all => 'MakeMaker installation path rules are Unix-specific'
    if $^O eq 'MSWin32' || $^O eq 'VMS';

my $make = $Config{make};
plan skip_all => 'make unavailable' if !$make;

my $temp = tempdir(CLEANUP => 1);
my $lib = abs_path('lib');
my $perl = $^X;

for my $mode (qw(perl site vendor)) {
  for my $setting (qw(INSTALL_BASE PREFIX)) {
    my $dir = File::Spec->catdir($temp, "generate-$mode-$setting");
    make_path($dir, File::Spec->catdir($dir, 'lib', 'Packlist'));
    my $module = File::Spec->catfile($dir, 'lib', 'Packlist', 'Probe.pm');
    open my $fh, '>', $module or die "$module: $!";
    print {$fh} "package Packlist::Probe; our \$VERSION = '0.01'; 1;\n";
    close $fh;
    my $mfpl = File::Spec->catfile($dir, 'Makefile.PL');
    open my $mf, '>', $mfpl or die "$mfpl: $!";
    print {$mf} "use ExtUtils::MakeMaker; WriteMakefile(NAME => 'Packlist::Probe', VERSION => '0.01', INSTALLDIRS => '$mode');\n";
    close $mf;
    my $base = File::Spec->catdir($temp, "prefix-$mode-$setting");
    my $cmd = qq{cd "$dir" && "$perl" -I"$lib" Makefile.PL $setting="$base"};
    is(system($cmd), 0, "generated $mode Makefile with $setting");
    my $file = File::Spec->catfile($dir, 'Makefile');
    open my $in, '<', $file or die "$file: $!";
    local $/;
    my $contents = <$in>;
    close $in;
    my %paths = (
        perl   => ['INSTALLARCHLIB','DESTINSTALLARCHLIB','perldirs'],
        site   => ['INSTALLSITEARCH','DESTINSTALLSITEARCH','sitedirs'],
        vendor => ['INSTALLVENDORARCH','DESTINSTALLVENDORARCH','vendordirs'],
    );
    my ($read, $write, $uninstall) = @{$paths{$mode}};
    my ($install_rule) = $contents =~ /(pure_${mode}_install\s*::.*?)(?=\npure_\w+_install\s*::|\ndoc_\w+_install\s*::)/s;
    like($install_rule, qr/\Qread "\E\$\($read\)\/auto\/\$\(FULLEXT\)\/\.packlist"/, "$mode $setting installation reads its effective location");
    like($install_rule, qr/\Qwrite "\E\$\($write\)\/auto\/\$\(FULLEXT\)\/\.packlist"/, "$mode $setting installation writes its destination location");
    my ($uninstall_rule) = $contents =~ /(uninstall_from_${uninstall}\s*::[^\n]*\n[^\n]*)/;
    like($uninstall_rule, qr/\$\($read\)\/auto\/\$\(FULLEXT\)\/\.packlist"/, "$mode $setting uninstall reads its effective location");
  }
}

# A real reinstall must preserve a path removed from the newer release.
# Run entirely within a disposable INSTALL_BASE, never in the system Perl tree.
{
    my $dir = File::Spec->catdir($temp, 'reinstall');
    my $base = File::Spec->catdir($temp, 'reinstall-root');
    make_path(File::Spec->catdir($dir, 'lib', 'Packlist'),
              File::Spec->catdir($dir, 'bin'));
    my $module = File::Spec->catfile($dir, 'lib', 'Packlist', 'Probe.pm');
    open my $fh, '>', $module or die "$module: $!";
    print {$fh} "package Packlist::Probe; our \$VERSION = '0.01'; 1;\n";
    close $fh;

    my $script = File::Spec->catfile($dir, 'bin', 'legacy-probe');
    open my $exe, '>', $script or die "$script: $!";
    print {$exe} "#!$perl\nprint qq{legacy};\n";
    close $exe;
    chmod 0755, $script;
    my $mfpl = File::Spec->catfile($dir, 'Makefile.PL');
    my $makefile_pl = sub {
        my ($with_script) = @_;
        open my $mf, '>', $mfpl or die "$mfpl: $!";
        print {$mf} "use ExtUtils::MakeMaker; WriteMakefile(NAME => 'Packlist::Probe', VERSION => '0.01',";
        print {$mf} " EXE_FILES => ['bin/legacy-probe']," if $with_script;
        print {$mf} " INSTALLDIRS => 'site');\n";
        close $mf;
    };
    my $build_install = sub {
        my $cmd = qq{cd "$dir" && "$perl" -I"$lib" Makefile.PL INSTALL_BASE="$base" && "$make" install};
        return system($cmd);
    };
    $makefile_pl->(1);
    is($build_install->(), 0, 'initial INSTALL_BASE installation succeeded');
    my $packlist = File::Spec->catfile($base, 'lib', 'perl5', $Config{archname},
                                        'auto', 'Packlist', 'Probe', '.packlist');
    open my $p1, '<', $packlist or die "$packlist: $!";
    my $before = do { local $/; <$p1> };
    close $p1;
    like($before, qr/legacy-probe/, 'initial packlist records legacy executable');
    unlink($script) or die "$script: $!";
    $makefile_pl->(0);
    is($build_install->(), 0, 'reinstallation without executable succeeded');
    open my $p2, '<', $packlist or die "$packlist: $!";
    my $after = do { local $/; <$p2> };
    close $p2;
    like($after, qr/legacy-probe/, 'reinstall preserves old executable in packlist');
}

done_testing;
