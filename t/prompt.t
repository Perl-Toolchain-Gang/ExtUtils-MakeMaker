#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

use strict;
use warnings;
use Test::More tests => 11;
use ExtUtils::MakeMaker;
use TieOut;
use TieIn;

eval q{
    prompt();
};
like( $@, qr/^Not enough arguments for ExtUtils::MakeMaker::prompt/,
                                            'no args' );

eval {
    prompt(undef);
};
like( $@, qr/^prompt function called without an argument/,
                                            'undef message' );

my $stdout = tie *STDOUT, 'TieOut' or die;


$ENV{PERL_MM_USE_DEFAULT} = 1;
is( prompt("Foo?"), '',     'no default' );
like( $stdout->read,  qr/^Foo\?\s*\n$/,      '  question' );

is( prompt("Foo?", undef), '',     'undef default' );
like( $stdout->read,  qr/^Foo\?\s*\n$/,      '  question' );

is( prompt("Foo?", 'Bar!'), 'Bar!',     'default' );
like( $stdout->read,  qr/^Foo\? \[Bar!\]\s+Bar!\n$/,      '  question' );

$ENV{PERL_MM_USE_DEFAULT} = 0;
close STDIN;
my $stdin = tie *STDIN, 'TieIn' or die;
$stdin->write("From STDIN");
ok( !-t STDIN,      'STDIN not a tty' );

is( prompt("Foo?", 'Bar!'), 'From STDIN',     'from STDIN' );
like( $stdout->read,  qr/^Foo\? \[Bar!\]\s*$/,      '  question' );

{
    my $CAN_DECODE = eval { require ExtUtils::MakeMaker::Locale; };
    SKIP: {
        skip 'Encode not available', 1 unless $CAN_DECODE;
        skip 'Not MSWin32', 1 unless $^O eq 'MSWin32';
        local $ExtUtils::MakeMaker::Locale::ENCODING_CONSOLE_IN = "cp850";
        $ENV{PERL_MM_USE_DEFAULT} = 0;
        $stdin->write("\x{86}\x{91}"); # åæ in cp850
        is( prompt("Foo?", 'Bar!'), "\x{e5}\x{e6}",
              'read cp850 encoded letters from STDIN' );
    }
}