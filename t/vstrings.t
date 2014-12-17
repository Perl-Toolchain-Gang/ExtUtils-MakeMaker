#!/usr/bin/perl -w

# test support for various forms of vstring versions in PREREQ_PM

# Magic for core
BEGIN {
    # Always run in t to unify behaviour with core
    chdir 't' if -d 't';
}

# Use things from t/lib/
use lib './lib';
use strict;
use warnings;
use TieOut;
use MakeMaker::Test::Utils qw(makefile_name);
use File::Temp qw[tempdir];
use Test::More;

use ExtUtils::MakeMaker;

my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );
chdir $tmpdir;

my $UNDEFRE = qr/Undefined requirement .* treated as '0'/;
my $UNPARSABLERE = qr/Unparsable\s+version/;
# [ pkg, version, okwarningRE, descrip ]
my @DATA = (
  [ Undef => undef, $UNDEFRE, 'Undef' ],
  [ ZeroLength => '', $UNDEFRE, 'Zero-length' ],
  [ SemiColon => '0;', $UNPARSABLERE, 'Semi-colon after 0' ],
  [ BrokenString => 'nan', $UNPARSABLERE, 'random string' ],
  [ Decimal2 => 1.2, qr/^$/, '2-part Decimal' ],
  [ Decimal2String => '1.2', qr/^$/, '2-part Decimal String' ],
  [ Decimal2Underscore => '1.02_03', qr/^$/, '2-part Underscore String' ],
  [ Decimal3String => '1.2.3', qr/^$/, '3-part Decimal String' ],
  [ BareV2String => v1.2, qr/^$/, '2-part bare v-string' ],
  [ BareV3String => v1.2.3, qr/^$/, '3-part bare V-string' ],
  [ V2DecimalString => 'v1.2', qr/^$/, '2-part v-decimal string' ],
  [ V3DecimalString => 'v1.2.3', qr/^$/, '3-part v-Decimal String' ],
  [ RangeString => '>= 5.0, <= 6.0', qr/^$/, 'Version range' ],
);

plan tests => (1 + (@DATA * 2));

ok my $stdout = tie(*STDOUT, 'TieOut'), 'tie STDOUT';

run_test(@$_) for @DATA;

sub capture_make {
    my ($package, $version) = @_ ;

    my $warnings = '';
    local $SIG{__WARN__} = sub {
        $warnings .= join '', @_;
    };

    local $ENV{PERL_CORE} = 0;

    WriteMakefile(
        NAME      => 'VString::Test',
        PREREQ_PM => { $package , $version }
    );

    return $warnings;
}

sub makefile_content {
    my $file = makefile_name;
    open my $fh, '<', $file or return "$file: $!\n";
    join q{}, grep { $_ =~ /Fake/i } <$fh>;
}

sub run_test {
  my ($pkg, $version, $okwarningRE, $descrip) = @_;
  SKIP: {
    skip "No vstring test <5.8", 2
      if $] < 5.008 && $pkg eq 'BareV2String' && $descrip =~ m!^2-part!;
    my $warnings;
    eval { $warnings = capture_make("Fake::$pkg" => $version); };
    is($@, '', "$descrip not fatal") or skip "$descrip WM failed", 1;
    $warnings =~ s#^Warning: prerequisite Fake::$pkg.* not found\.\n##m;
    like $warnings, $okwarningRE, "$descrip handled right";
  }
#  diag makefile_content();
}
