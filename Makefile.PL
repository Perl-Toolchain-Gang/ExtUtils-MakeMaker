#!/usr/bin/perl -w

# A template for Makefile.PL.
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.

BEGIN { require 5.006; }
use strict;

use lib ".";
use my::bundles;  # Must be used before anything else to set up bundled dependencies

use lib qw(lib);    # build ourself with ourself

use File::Spec;
use ExtUtils::MakeMaker 6.50;

my $BUILDING_AS_PACKAGE = $ENV{BUILDING_AS_PACKAGE};

BEGIN {
    die "You have File::Spec version $File::Spec::VERSION\n" . "ExtUtils::MakeMaker requires File::Spec >= 0.8 to build at all.\n"
      if $File::Spec::VERSION < 0.8;
}

my $PACKAGE = 'ExtUtils::MakeMaker';
my $version = do { no strict 'refs'; ${ $PACKAGE . '::VERSION' }; };
$version =~ s/_//;      # for X.Y_Z alpha releases
( my $PACKAGE_FILE = $PACKAGE ) =~ s|::|/|g;
my $LAST_API_CHANGE = 5.50;

my $Is_VMS = $^O eq 'VMS';

eval "require $PACKAGE";

unless ( $@ ) {         # Make sure we did find the module.
    print <<"CHANGE_WARN" if $version < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

check_environment();

my %Extra_Params  = ();
my %Extra_Prereqs = ();

# Special case for MakeMaker being built as a vendor package
if( $BUILDING_AS_PACKAGE ) {
    # Some of these are lower than what we bundle.  That's ok, we
    # bundle the latest because we might as well, but we don't want to
    # burden vendors with having to update everything.
    %Extra_Prereqs = (
        'CPAN::Meta'               => '2.113640',
        'CPAN::Meta::YAML'         => '0.002',
        'ExtUtils::Command'        => '1.16',
        'ExtUtils::Install'        => '1.52',
        'ExtUtils::Manifest'       => '1.58',
        'File::Temp'               => '0.22',
        'JSON::PP'                 => '2.27103',
        'Parse::CPAN::Meta'        => '1.4400',
        'Scalar::Util'             => '1.13',
        'version'                  => '0.82',
        'CPAN::Meta::Requirements' => '2.121',
    );

    $Extra_Prereqs{'JSON::PP::Compat5006'} = '1.09' if $] < 5.008;
}
else {
   eval {
      require ExtUtils::Manifest;
      require ExtUtils::Command;
      require ExtUtils::Install;
   };
   if ( $@ ) {
     $Extra_Params{PERL} = "$^X -Iinc";
   }

   my::bundles::copy_bundles("bundled", "inc");
}

# Test::Harnesses prior to 2.00 shoved all of @INC onto the command line
# when a test had -T.  This made it too long.  So we need a Test::Harness
# > 2.00 on VMS for t/testlib.t
$Extra_Prereqs{'Test::Harness'} = 2.00 if $^O eq 'VMS';

my $MM = WriteMakefile(
    NAME         => $PACKAGE,
    VERSION_FROM => "lib/$PACKAGE_FILE.pm",    # finds $VERSION

    PREREQ_PM => {
        %Extra_Prereqs,
        'File::Spec'     => 0.8,               # splitpath(), rel2abs()
        'Pod::Man'       => 0,                 # manifypods needs Pod::Man
        'File::Basename' => 0,
        DirHandle        => 0,
    },

    MIN_PERL_VERSION => '5.006',
    PMLIBDIRS        => [qw(lib inc)],
    PMLIBPARENTDIRS  => [qw(lib inc)],         # PMLIBPARENTDIRS is an experimental feature
    EXE_FILES        => [qw(bin/instmodsh)],

    META_MERGE => {
        no_index => {
            package   => [ 'DynaLoader', 'in' ],    # "in" is a PAUSE misparse.
            directory => [ 'bundled', 'my' ],
        },
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'https://metacpan.org/release/ExtUtils-MakeMaker',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MakeMaker',
            repository  => 'http://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker',
            MailingList => 'makemaker@perl.org',
        },
    },

    CONFIGURE_REQUIRES => {},                  # We don't need ourself to install ourself.
    BUILD_REQUIRES     => { 'Data::Dumper' => 0, },
    INSTALLDIRS        => ( $] < 5.012 ? 'perl' : 'site' ),
    LICENSE            => 'perl',
    ABSTRACT_FROM      => "lib/$PACKAGE_FILE.pm",
    AUTHOR             => 'Michael G Schwern <schwern@pobox.com>',

    realclean              => {
        FILES   => "inc"
    },

    %Extra_Params,

    $^O =~ /win/i
    ? (
        dist => {
            TAR      => 'ptar',
            TARFLAGS => '-c -C -f',
        },
      )
    : (),
);

if ( !$Is_VMS && $MM->{PERL} =~ /\S\s+\S/ ) {
    require Test::Harness;
    my $th_version = defined $Test::Harness::VERSION ? $Test::Harness::VERSION : 0;
    print <<SPACE_WARN if $th_version < 2.27;

NOTE: Your Perl looks like it contains a space in the path name.
MakeMaker is now OK with that but your version of Test::Harness is not
which means 'make test' will likely puke.

You will have to install this new version of MakeMaker, then upgrade
Test::Harness from CPAN, then run the MakeMaker tests.

SPACE_WARN

}

# Display warnings about the environment.
sub check_environment {
    if ( $Is_VMS && $ENV{bin} ) {
        print <<BIN_WARN;

The logical name BIN may be present.  This may interfere with MakeMaker's
tests and operations.  GNV is the prime suspect for setting this.

BIN_WARN

        sleep 2;
    }
}

{

    package MY;

    # Make sure PERLRUN uses the MakeMaker about to be installed
    # and not the currently installed one.
    sub init_PERL {
        my ( $self ) = shift;
        $self->SUPER::init_PERL;

        $self->{$_} .= q[ "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"] for qw( PERLRUN FULLPERLRUN ABSPERLRUN );
    }

    # Test with multiple versions of perl
    sub dist_test {
        my $self = shift;

        my $make = $self->SUPER::dist_test( @_ );
        return $make unless $ENV{AUTHOR_TESTING} and $ENV{AUTHOR_TESTING} eq 'MSCHWERN';

        # Strip off all the whitespace at the end, we'll put our own in.
        $make =~ s{\s+\z}{\n};

        my @perls = qw(
            perl5.6.1
            perl5.6.2
            perl5.8.1
            perl5.8.5
            perl5.8.8
            perl5.8.9
            perl5.10
            perl5.10.0
            perl5.10.1
            perl5.12
            perl5.12.3
            perl5.12.4
            perl5.14.0
            perl5.14.1
            perl5.14.2
            perl5.16.0
            perl5.16.1
            perl5.16.2
        );

        for my $perl ( @perls ) {
            if( !`which $perl` ) {
                print STDERR "Missing $perl";
                next;
            }

            $make .= sprintf <<'END', $perl;
	cd $(DISTVNAME) && $(MAKE) clean && %s Makefile.PL && $(MAKE) test $(PASTHRU)
END
        }

        $make .= "\n";

        return $make;
    }


    sub postamble {
        my $self = shift;

        return <<'END';
critic : .perlcriticrc
	find lib -name '*.pm' -print0 | xargs -0 perlcritic

END

    }
}
