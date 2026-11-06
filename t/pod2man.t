#!/usr/bin/perl -w

# Test our simulation of pod2man

use strict;
use warnings;
use lib 't/lib';

use ExtUtils::Command::MM;

use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

use Test::More tests => 4;

# The argument to perm_rw was optional.
# [rt.cpan.org 35190]
{
    my $warnings;
    local $SIG{__WARN__} = sub {
        $warnings .= join '', @_;
    };

    pod2man("--perm_rw");

    like $warnings, qr/Option perm_rw requires an argument/;
};


# No "uninitialized value" warnings when Makefile does not exist (GH #479).
# When the man page is up-to-date relative to the pod source, pod2man skips
# regeneration by comparing mtimes.  The third comparison is against
# "Makefile" (or the configured FIRST_MAKEFILE).  If that file does not exist,
# mtime() returns undef and Perl emits an uninitialized-value warning.
{
    my $cwd = getcwd();
    my $tmpdir = tempdir(CLEANUP => 1);
    chdir $tmpdir or die "chdir $tmpdir: $!";

    # Create a simple pod source file.
    open my $fh, '>', 'foo.pod' or die $!;
    print $fh "=head1 NAME\n\nfoo - test\n\n=cut\n";
    close $fh;

    # Create a man page with a future mtime so it appears up-to-date.
    open $fh, '>', 'foo.1' or die $!;
    print $fh "man page\n";
    close $fh;

    my $future = time() + 3600;
    utime $future, $future, 'foo.1';

    # Ensure there is no Makefile in this directory.
    die "Unexpected Makefile in tmpdir" if -e 'Makefile';

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    local @ARGV = ('foo.pod', 'foo.1');
    pod2man();

    chdir $cwd or die "chdir $cwd: $!";

    my @uninit = grep { /uninitialized/ } @warnings;
    is scalar(@uninit), 0,
        'no uninitialized-value warnings when Makefile is absent (GH #479)';
}


# Simulate the failure of Pod::Man loading.
# pod2man() should react gracefully.
{
    local @INC = @INC;
    unshift @INC, sub {
        die "Simulated Pod::Man failure\n" if $_[1] eq 'Pod/Man.pm';
    };
    local %INC = %INC;
    delete $INC{"Pod/Man.pm"};

    my $warnings;
    local $SIG{__WARN__} = sub {
        $warnings .= join '', @_;
    };

    ok !pod2man();
    is $warnings, <<'END'
Pod::Man is not available: Simulated Pod::Man failure
Man pages will not be generated during this install.
END

}
