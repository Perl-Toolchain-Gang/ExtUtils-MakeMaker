#!/usr/bin/perl -w

use 5.006;
use strict;

use lib ".";
use my::bundles;  # Must be used before anything else to set up bundled dependencies

use lib qw(lib);    # build ourself with ourself

use File::Spec;
use ExtUtils::MakeMaker 6.50;

my $BUILDING_AS_PACKAGE = $ENV{BUILDING_AS_PACKAGE} || ( grep { m!^\-\-release$! } @ARGV );

my $Is_VMS = $^O eq 'VMS';

check_environment();

my (%Extra_Params, %Extra_Prereqs, %Extra_Test_Prereqs);

# Special case for MakeMaker being built as a vendor package
if( $BUILDING_AS_PACKAGE ) {
    # Some of these are lower than what we bundle.  That's ok, we
    # bundle the latest because we might as well, but we don't want to
    # burden vendors with having to update everything.
    %Extra_Prereqs = (
        'CPAN::Meta'               => '2.143240', # compat with CMR 2.130
        'ExtUtils::Install'        => '1.52',
        'ExtUtils::Manifest'       => '1.70',
        'version'                  => '0',
    );
    $Extra_Prereqs{'JSON::PP::Compat5006'} = '1.09' if "$]" < 5.008;

    %Extra_Test_Prereqs = (
        'File::Temp'               => '0.22',
        'Scalar::Util'             => '1.13',
    );
}
else {
   eval {
      require ExtUtils::Manifest;
      require ExtUtils::Install;
   }
   or do {
     $Extra_Params{PERL} = "$^X -Iinc";
   };

   my::bundles::copy_bundles("bundled", "inc");
}

# Test::Harnesses prior to 2.00 shoved all of @INC onto the command line
# when a test had -T.  This made it too long.  So we need a Test::Harness
# > 2.00 on VMS for t/testlib.t
$Extra_Prereqs{'Test::Harness'} = 2.00 if $^O eq 'VMS';

my $MM = WriteMakefile(
    NAME          => 'ExtUtils::MakeMaker',
    VERSION_FROM  => "lib/ExtUtils/MakeMaker.pm",
    ABSTRACT_FROM => "lib/ExtUtils/MakeMaker.pm",

    PREREQ_PM => {
        %Extra_Prereqs,
        'File::Spec'     => 0.8,               # splitpath(), rel2abs()
        'Pod::Man'       => 0,                 # manifypods needs Pod::Man
        'File::Basename' => 0,
        'Data::Dumper'   => 0,
        ("$]" > 5.008 ? (Encode => 0) : ()),
    },
    TEST_REQUIRES    => \%Extra_Test_Prereqs,

    MIN_PERL_VERSION => '5.006',
    PMLIBDIRS        => [qw(lib inc)],
    PMLIBPARENTDIRS  => [qw(lib inc)],         # PMLIBPARENTDIRS is an experimental feature
    EXE_FILES        => [qw(bin/instmodsh)],

    META_MERGE => {
        no_index => {
            # Module::Metadata is inferring version from $version::VERSION
            # "in" is a PAUSE misparse.
            package   => [ qw(DynaLoader in version) ],
            directory => [ qw(bundled my) ],
        },
        resources => {
            license     => 'https://dev.perl.org/licenses/',
            homepage    => 'https://metacpan.org/release/ExtUtils-MakeMaker',
            bugtracker  => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MakeMaker',
            repository  => 'https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker',
            MailingList => 'makemaker@perl.org',
        },
    },

    CONFIGURE_REQUIRES => {},                  # We don't need ourself to install ourself.
    BUILD_REQUIRES     => {},                  # We don't need ourself to build ourself.
    INSTALLDIRS        => ( "$]" < 5.012 ? 'perl' : 'site' ),
    LICENSE            => 'perl',
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

    sub special_targets {
      my ( $self ) = shift;
      my $make_frag = $self->SUPER::special_targets(@_);
      return $make_frag if $Is_VMS or $self->is_make_type('dmake'); # not supported in MMS, MMK or by `dmake`
      $make_frag .= <<'MAKE_FRAG';
.NOTPARALLEL: pure_all

MAKE_FRAG
      return $make_frag;
    }

}
