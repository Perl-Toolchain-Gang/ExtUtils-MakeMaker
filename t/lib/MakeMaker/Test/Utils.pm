package MakeMaker::Test::Utils;

use strict;
use Config;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;
@ISA = qw(Exporter);

$VERSION = 0.01;

@EXPORT = qw(which_perl perl_lib makefile_name makefile_backup
             make make_run
            );

my $Is_VMS = $^O eq 'VMS';


=head1 NAME

MakeMaker::Test::Utils - Utility routines for testing MakeMaker

=head1 SYNOPSIS

  use MakeMaker::Test::Utils;

  my $perl     = which_perl;
  perl_lib;

  my $makefile      = makefile_name;
  my $makefile_back = makefile_backup;

  my $make          = make;
  my $make_run      = make_run;

=head1 DESCRIPTION

A consolidation of little utility functions used through out the
MakeMaker test suite.

=head2 Functions

The following are exported by default.

=over 4

=item B<which_perl>

  my $perl = which_perl;

Returns a path to perl which is safe to use in a command line, no
matter where you chdir to.

=cut

sub which_perl {
    my $perl = $^X;
    $perl ||= 'perl';

    # VMS should have 'perl' aliased properly
    return $perl if $Is_VMS;

    $perl = File::Spec->rel2abs( $perl );

    unless( -x $perl ) {
        # $^X was probably 'perl'
        foreach my $path (File::Spec->path) {
            $perl = File::Spec->catfile($path, $^X);
            last if -x $perl;
        }
    }

    return $perl;
}

=item B<perl_lib>

  perl_lib;

Sets up environment variables so perl can find its libraries.

=cut

my $old5lib = $ENV{PERL5LIB};
my $had5lib = exists $ENV{PERL5LIB};
sub perl_lib {
                                       # perl-src/lib/ExtUtils/t/Foo
    $ENV{PERL5LIB} .= $ENV{PERL_CORE} ? qq{../../../../lib}
                                       # ExtUtils-MakeMaker/t/Foo
                                      : qq{-I../../blib/lib};
}

END { $ENV{PERL5LIB} = $old5lib if $had5lib }


=item B<makefile_name>

  my $makefile = makefile_name;

MakeMaker doesn't always generate 'Makefile'.  It returns what it
should generate.

=cut

sub makefile_name {
    return $Is_VMS ? 'descrip.mms' : 'Makefile';
}   

=item B<makefile_backup>

  my $makefile_old = makefile_backup;

Returns the name MakeMaker will use for a backup of the current
Makefile.

=cut

sub makefile_backup {
    my $makefile = makefile_name;
    return $Is_VMS ? $makefile : "$makefile.old";
}

=item B<make>

  my $make = make;

Returns a good guess at the make to run.

=cut

sub make {
    my $make = $Config{make};
    $make = $ENV{MAKE} if exists $ENV{MAKE};

    return $make;
}

=item B<make_run>

  my $make_run = make_run;

Returns the make to run as with make() plus any necessary switches.

=cut

sub make_run {
    my $make = make;
    $make .= ' -nologo' if $make eq 'nmake';

    return $make;
}

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=cut

1;
