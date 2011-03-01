#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    use Cwd;
    chdir 't' if -d 't';
    use lib getcwd() . '/lib', getcwd() . '/../lib';
}

BEGIN {

    package MockEUMM;
    use base 'File::Spec';    # what.
    sub new { return bless {}, 'MockEUMM'; }
}

package liblist_kid_test;

use Test::More;
use ExtUtils::MakeMaker::Config;
use File::Spec;

run();
done_testing();

exit;

sub _kid_ext;

sub run {
    use_ok( 'ExtUtils::Liblist::Kid' );

    move_to_os_test_data_dir();
    alias_kid_ext_for_convenience();

    conf_reset();

    return test_kid_win32() if $^O eq 'MSWin32';
    return;
}

# This allows us to get a clean playing field and ensure that the current
# system configuration does not affect the test results.

sub conf_reset {
    delete $Config{$_} for keys %Config;
}

sub move_to_os_test_data_dir {
    my %os_test_dirs = ( MSWin32 => 'liblist/win32', );
    chdir $os_test_dirs{$^O} if $os_test_dirs{$^O};

    return;
}

sub alias_kid_ext_for_convenience {
    my %os_ext_funcs = ( MSWin32 => \&ExtUtils::Liblist::Kid::_win32_ext, );
    *_kid_ext = $os_ext_funcs{$^O};

    return;
}

sub test_kid_win32 {

    $Config{installarchlib} = 'lib';

    is_deeply( [ _ext() ],                           [ '',                                     '', '',                                     '' ], 'empty input results in empty output' );
    is_deeply( [ _ext( 'unreal_test' ) ],            [ '',                                     '', '',                                     '' ], 'non-existent file results in empty output' );
    is_deeply( [ _ext( 'direct_test' ) ],            [ 'direct_test.lib',                      '', 'direct_test.lib',                      '' ], 'existent file results in a path to the file. .lib is default extension with empty %Config' );
    is_deeply( [ _ext( 'test' ) ],                   [ 'lib\CORE\test.lib',                    '', 'lib\CORE\test.lib',                    '' ], '$Config{installarchlib}/CORE is the default search dir aside from cwd' );
    is_deeply( [ _ext( 'double' ) ],                 [ 'double.lib',                           '', 'double.lib',                           '' ], 'once an instance of a lib is found, the search stops' );
    is_deeply( [ _ext( 'test.lib' ) ],               [ 'lib\CORE\test.lib',                    '', 'lib\CORE\test.lib',                    '' ], 'the extension is not tacked on twice' );
    is_deeply( [ _ext( 'test.a' ) ],                 [ 'lib\CORE\test.a.lib',                  '', 'lib\CORE\test.a.lib',                  '' ], 'but it will be tacked onto filenamess with other kinds of library extension' );
    is_deeply( [ _ext( 'test test2' ) ],             [ 'lib\CORE\test.lib lib\CORE\test2.lib', '', 'lib\CORE\test.lib lib\CORE\test2.lib', '' ], 'multiple existing files end up separated by spaces' );
    is_deeply( [ _ext( 'test test2 unreal_test' ) ], [ 'lib\CORE\test.lib lib\CORE\test2.lib', '', 'lib\CORE\test.lib lib\CORE\test2.lib', '' ], "some existing files don't cause false positives" );

    is_deeply( [ scalar _ext( 'test' ) ], ['lib\CORE\test.lib'], 'asking for a scalar gives a single string' );

    is_deeply( [ _ext( undef,              undef, 1 ) ], [ '',                                  '', '',                                  '', [] ],                    'asking for real names with empty input results in an empty extra array' );
    is_deeply( [ _ext( 'unreal_test',      undef, 1 ) ], [ '',                                  '', '',                                  '', [] ],                    'asking for real names with non-existent file results in an empty extra array' );
    is_deeply( [ _ext( 'test',             undef, 1 ) ], [ 'lib\CORE\test.lib',                 '', 'lib\CORE\test.lib',                 '', ['lib/CORE\test.lib'] ], 'asking for real names with an existent file results in an extra array with a mixed-os file path?!' );
    is_deeply( [ _ext( 'direct_test test', undef, 1 ) ], [ 'direct_test.lib lib\CORE\test.lib', '', 'direct_test.lib lib\CORE\test.lib', '', ['lib/CORE\test.lib'] ], 'files in cwd do not appear in the real name list?!' );

    is_deeply( [ _ext( 'test :nosearch unreal_test test2' ) ],         [ 'lib\CORE\test.lib unreal_test test2',              '', 'lib\CORE\test.lib unreal_test test2',              '' ], ':nosearch can force passing through of filenames as they are' );
    is_deeply( [ _ext( 'test :nosearch unreal_test :search test2' ) ], [ 'lib\CORE\test.lib unreal_test lib\CORE\test2.lib', '', 'lib\CORE\test.lib unreal_test lib\CORE\test2.lib', '' ], ':search enables file searching again' );
    is_deeply( [ _ext( 'test :meep test2' ) ],                         [ 'lib\CORE\test.lib lib\CORE\test2.lib',             '', 'lib\CORE\test.lib lib\CORE\test2.lib',             '' ], 'unknown :flags are safely ignored' );

    my $curr = File::Spec->rel2abs( '' );
    is_deeply( [ _ext( "-L$curr/dir dir_test" ) ], [ $curr . '\dir\dir_test.lib',         '', $curr . '\dir\dir_test.lib',         '' ], 'directories in -L parameters are searched' );
    is_deeply( [ _ext( "-L/non_dir dir_test" ) ],  [ '',                                  '', '',                                  '' ], 'non-existent -L dirs are ignored safely' );
    is_deeply( [ _ext( "-Ldir dir_test" ) ],       [ $curr . '\dir\dir_test.lib',         '', $curr . '\dir\dir_test.lib',         '' ], 'relative -L directories work' );
    is_deeply( [ _ext( "-L\"di r\" dir_test" ) ],  [ '"' . $curr . '\di r\dir_test.lib"', '', '"' . $curr . '\di r\dir_test.lib"', '' ], '-L directories with spaces work' );

    $Config{libpth} = 'lib with space';

    return;
}

sub _ext { _kid_ext( MockEUMM->new, @_ ); }

