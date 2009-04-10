#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use TieOut;
use Test::More 'no_plan';

use Config;
use ExtUtils::MakeMaker;

ok( my $stdout = tie *STDOUT, 'TieOut' );    

# Create a normalized MM object to test with
my $mm = bless {}, "MM";
$mm->{PERL_SRC} = 0;
$mm->{UNINSTALLED_PERL} = 0;


ok $mm->arch_check(
    "/foo/bar/arch/Config.pm",
    "/foo/bar/arch/Config.pm"
);


# Different architecures.
{
    ok !$mm->arch_check(
        "/foo/bar/arch1/Config.pm",
        "/foo/bar/arch2/Config.pm"
    );

    like $stdout->read, qr{\Q
Your perl and your Config.pm seem to have different ideas about the 
architecture they are running on.
Perl thinks: [arch1]
Config says: [$Config{archname}]
This may or may not cause problems. Please check your installation of perl 
if you have problems building this extension.
};

}


# PERL_SRC is set, no check is done
{
    local $mm->{PERL_SRC} = 1;
    ok $mm->arch_check(
        "/this/is/different",
        "/and/so/is/this"
    );

    is $stdout->read, '';
}


# UNINSTALLED_PERL is set, no message is sent
{
    local $mm->{UNINSTALLED_PERL} = 1;
    ok !$mm->arch_check(
        "/this/is/different",
        "/and/so/is/this"
    );

    like $stdout->read, qr{^Have .*\nWant .*$};
}
