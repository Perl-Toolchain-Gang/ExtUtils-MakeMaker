#!/usr/bin/perl -w

use File::Find;
use File::Spec;
use Test::More;

my $Has_Test_Pod;
BEGIN {
    $Has_Test_Pod = eval 'use Test::Pod 0.95; 1';
}

my(@modules);

chdir 'lib';
find( sub {
        return if /~$/;
        if( $File::Find::dir =~ /^blib|t$/ ) {
            $File::Find::prune = 1;
            return;
        }
        push @modules, $File::Find::name if /\.pm$/;
    }, File::Spec->curdir
);

plan tests => scalar @modules * 2;
foreach my $file (@modules) {
    my $file = File::Spec->canonpath($file);
    local @INC = @INC;
    unshift @INC, File::Spec->curdir;
    eval q{ require($file) };
    is( $@, '', "require $file" );

    SKIP: {
        skip "Test::Pod not installed" unless $Has_Test_Pod;
        pod_file_ok($file);
    }
    
}
