#!/usr/bin/perl -w

use File::Find;
use File::Spec;
use Test::More;

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

plan tests => scalar @modules;
foreach my $file (@modules) {
    my $file = File::Spec->canonpath($file);
    local @INC = @INC;
    unshift @INC, File::Spec->curdir;
    eval q{ require($file) };
    is( $@, '', "require $file" );
}
