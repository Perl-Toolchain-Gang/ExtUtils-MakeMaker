package ExtUtils::Command::MM;

use strict;

require 5.005_03;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT  = qw(test_harness pod2man);
$VERSION = '0.01';

=head1 NAME

ExtUtils::Command::MM - Commands for the MM's to use in Makefiles

=head1 SYNOPSIS

  perl -MExtUtils::Command::MM -e "function" -- arguments...


=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>  The interface is not stable.

ExtUtils::Command::MM encapsulates code which would otherwise have to
be done with large "one" liners.

They all read their input from @ARGV unless otherwise noted.

Any $(FOO) used in the examples are make variables, not Perl.

=over 4

=item B<test_harness>

  test_harness($verbose, @test_libs);

Runs the tests on @ARGV via Test::Harness passing through the $verbose
flag.  Any @test_libs will be unshifted onto the test's @INC.

@test_libs are run in alphabetical order.

=cut

sub test_harness {
    require Test::Harness;
    require File::Spec;

    $Test::Harness::verbose = shift;

    local @INC = @INC;
    unshift @INC, map { File::Spec->rel2abs($_) } @_;
    Test::Harness::runtests(sort { lc $a cmp lc $b } @ARGV);
}



=item B<pod2man>

  pod2man( '--option=value',
           $podfile1 => $manpage1,
           $podfile2 => $manpage2,
           ...
         );

pod2man() is a function performing most of the duties of the pod2man
program.  Its arguments are exactly the same as pod2man as of 5.8.0
with the addition of:

    --perm_rw   octal permission to set the resulting manpage to

And the removal of:

    --verbose/-v
    --help/-h

=cut

sub pod2man {
    require Pod::Man;
    require Getopt::Long;

    my %options = ();

    # We will cheat and just use Getopt::Long.  We fool it by putting
    # our arguments into @ARGV.  Should be safe.
    local @ARGV = @_;
    Getopt::Long::config ('bundling_override');
    Getopt::Long::GetOptions (\%options, 
                'section|s=s', 'release|r=s', 'center|c=s',
                'date|d=s', 'fixed=s', 'fixedbold=s', 'fixeditalic=s',
                'fixedbolditalic=s', 'official|o', 'quotes|q=s', 'lax|l',
                'name|n=s', 'perm_rw=i'
    );

    # If there's no files, don't bother going further.
    return 0 unless @ARGV;

    # Official sets --center, but don't override things explicitly set.
    if ($options{official} && !defined $options{center}) {
        $options{center} = 'Perl Programmers Reference Guide';
    }

    # This isn't a valid Pod::Man option and is only accepted for backwards
    # compatibility.
    delete $options{lax};

    my $parser = Pod::Man->new(%options);

    do {{  # so 'next' works
        my ($infile, $outfile) = splice(@ARGV, 0, 2);

    next if ((-e $outfile) &&
         (-M $outfile < -M $infile) &&
         (-M $outfile < -M "Makefile"));

    print "Manifying $outfile\n";

    $parser->parse_from_file($infile, $outfile)
      or do { warn("Could not install $outfile\n");  next };

    if ($options{perm_rw}) {
        chmod(oct($options{perm_rw}), $outfile)
          or do { warn("chmod $options{perm_rw} $outfile: $!\n"); next };
    }
    }} while @ARGV;

    return 1;
}


=back

=cut

1;
