#!/usr/bin/perl -w

# Test ExtUtils::Install.

BEGIN {
    if( $ENV{PERL_CORE} ) {
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use strict;
use TieOut;
use File::Path;
use File::Spec;

use Test::More tests => 17;

BEGIN { use_ok('ExtUtils::Install') }

# Check exports.
foreach my $func (qw(install uninstall pm_to_blib install_default)) {
    can_ok(__PACKAGE__, $func);
}


chdir 'Big-Dummy';

my $stdout = tie *STDOUT, 'TieOut';
pm_to_blib( { 'lib/Big/Dummy.pm' => 'blib/lib/Big/Dummy.pm' },
            'blib/lib/auto'
          );
ok( -d 'blib/lib',              'pm_to_blib created blib dir' );
ok( -r 'blib/lib/Big/Dummy.pm', '  copied .pm file' );
ok( -r 'blib/lib/auto',         '  created autosplit dir' );
is( $stdout->read, "cp lib/Big/Dummy.pm blib/lib/Big/Dummy.pm\n" );

pm_to_blib( { 'lib/Big/Dummy.pm' => 'blib/lib/Big/Dummy.pm' },
            'blib/lib/auto'
          );
ok( -d 'blib/lib',              'second run, blib dir still there' );
ok( -r 'blib/lib/Big/Dummy.pm', '  .pm file still there' );
ok( -r 'blib/lib/auto',         '  autosplit still there' );
is( $stdout->read, "Skip blib/lib/Big/Dummy.pm (unchanged)\n" );


install( { 'blib/lib' => 'install-test/lib/perl',
           read   => 'install-test/packlist',
           write  => 'install-test/packlist'
         } );
ok( -d 'install-test/lib/perl',                 'install made dir' );
ok( -r 'install-test/lib/perl/Big/Dummy.pm',    '  .pm file installed' );
ok( -r 'install-test/packlist',                 '  packlist exists' );

open(PACKLIST, 'install-test/packlist' );
my %packlist = map { chomp;  ($_ => 1) } <PACKLIST>;
close PACKLIST;

my $native_dummy = File::Spec->catfile(qw(install-test lib perl Big Dummy.pm));
is_deeply( \%packlist, { $native_dummy => 1 },
                              'packlist written');

END { rmtree 'blib' }
