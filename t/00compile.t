#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';

use File::Find;
use File::Spec;
use Test::More;

my $Has_Test_Pod;
BEGIN {
    $Has_Test_Pod = eval 'use Test::Pod 0.95; 1';
}

my(@modules);

chdir File::Spec->catdir(File::Spec->updir, 'lib');
find( sub {
        return if /~$/;
        if( $File::Find::dir =~ /^blib|t$/ ) {
            $File::Find::prune = 1;
            return;
        }
        push @modules, $File::Find::name if /\.pm$/;
    }, '.'  # yes, File::Find always returns unixy files
);

plan tests => scalar @modules * 2;
foreach my $file (@modules) {
    # attempting to normalize the file to be something like what Perl
    # puts in %INC via require Foo::Bar.  Can't use canonpath, it will
    # nativize the filename.
    $file =~ s{^\./}{};  # this is ok, we have unix filenames for sure

    local @INC = @INC;
    unshift @INC, File::Spec->curdir;

    # This piece of insanity brought to you by non-case preserving
    # file systems!  We have extutils/command.pm, %INC has 
    # ExtUtils/Command.pm
    eval q{ require($file) } unless grep { lc $file =~ lc $_ } keys %INC;
    is( $@, '', "require $file" );

    SKIP: {
        skip "Test::Pod not installed", 1 unless $Has_Test_Pod;
        pod_file_ok($file);
    }
    
}
