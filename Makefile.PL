#!/usr/bin/perl -w

# A template for Makefile.PL.
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.

BEGIN { require 5.006; }
use strict;

use lib qw(lib inc);    # build ourself with ourself
use File::Spec;
use ExtUtils::MakeMaker 6.50;

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

# Test::Harnesses prior to 2.00 shoved all of @INC onto the command line
# when a test had -T.  This made it too long.  So we need a Test::Harness
# > 2.00 on VMS for t/testlib.t
my %prereq = ();
$prereq{'Test::Harness'} = 2.00 if $^O eq 'VMS';

check_environment();

my $MM = WriteMakefile(
    NAME         => $PACKAGE,
    VERSION_FROM => "lib/$PACKAGE_FILE.pm",    # finds $VERSION

    PREREQ_PM => {
        %prereq,
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
            package => [ 'DynaLoader', 'in' ],    # "in" is a PAUSE misparse.
        },
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://makemaker.org',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MakeMaker',
            repository  => 'http://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker',
            MailingList => 'makemaker@perl.org',
        },
    },

    CONFIGURE_REQUIRES => {},                                        # We don't need ourself to install ourself.
    BUILD_REQUIRES     => { 'Data::Dumper' => 0, },
    INSTALLDIRS        => 'perl',
    LICENSE            => 'perl',
    ABSTRACT_FROM      => "lib/$PACKAGE_FILE.pm",
    AUTHOR             => 'Michael G Schwern <schwern@pobox.com>',

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

    sub init_PM {
        my $self = shift;

        $self->SUPER::init_PM;

        # Only override older versions of modules with ours in inc/
        for my $inc ( grep /^inc/, keys %{ $self->{PM} } ) {
            next unless $inc =~ /\.pm$/;

            my $installed = _find_installed( $inc );

            # Shut up "isn't numeric" warning on X.Y_Z versions.
            local $^W = 0;
            my $installed_version = $installed ? $self->parse_version( $installed ) : undef;
            my $inc_version       = $self->parse_version( $inc );
            my $module            = _module_name( $inc );

            if ( !$installed ) {
                print qq{Using included version of $module ($inc_version) because it is not already installed.\n};
            }
            elsif ( $module =~ /^Scalar::Util/ and _scalar_util_is_fine( $installed ) ) {
                delete $self->{PM}{$inc};
            }
            elsif ( $installed_version >= $inc_version ) {
                delete $self->{PM}{$inc};
            }
            else {
                print qq{Using included version of $module ($inc_version) as it is newer than the installed version ($installed_version).\n};
            }
        }

        _remove_MANIFEST_SKIP( $self );
    }

    sub _scalar_util_is_fine {
        my ( $file ) = @_;
        my @exports = extract_exports( $file );
        return 1 if grep /^blessed$/, @exports;
        return 0;
    }

    sub extract_exports {
        my ( $parsefile ) = @_;

        my $code = do {
            open my $fh, "<", $parsefile or die "Could not open '$parsefile': $!";
            local $/;
            <$fh>;
        };

        $code =~ s/[\r\n]//g;

        my $exports = '';
        for my $export_var_name ( qw( EXPORT EXPORT_OK ) ) {
            my ( $export ) = (
                $code =~ /
                    (
                        \@$export_var_name  # A possible export var starts here,
                        \s*                 # sometimes followed by whitespace,
                        =                   # a mandatory assignment,
                        \s*                 # some more optional whitespace,
                        qw\(                # then the start of a word list,
                            [\w\s]+         # then the exports, consisting of alphanum + optional whitespace,
                        \)                  # followed by the word list closing,
                        \s*                 # some more optional whitespace,
                        ;                   # and a mandatory semicolon.
                    )
                /x
            );
            $exports .= $export if $export;
        }

        my $eval = qq{
            my \@EXPORT;
            my \@EXPORT_OK;
            $exports
            return ( \@EXPORT, \@EXPORT_OK );
        };
        my @EXPORTS = eval( $eval );    ## no critic
        warn "Could not eval '$eval' in $parsefile: $@" if $@;

        return @EXPORTS;
    }

    # If ExtUtils::Manifest isn't included don't include MANIFEST.SKIP either.
    sub _remove_MANIFEST_SKIP {
        my $self = shift;

        return if grep /Manifest\.pm$/i, keys %{ $self->{PM} };

        my ( $maniskip_key ) = grep /MANIFEST\.SKIP$/i, keys %{ $self->{PM} };
        return unless $maniskip_key;

        return delete $self->{PM}{$maniskip_key};
    }

    sub _find_installed {
        my $file = shift;

        $file =~ s{^(\W*)inc\W}{$1}i;

        for my $inc ( grep { $_ ne 'inc' } @INC ) {
            my $path = File::Spec->catfile( $inc, $file );
            return $path if -r $path;
        }

        return;
    }

    sub _module_name {
        my $path = shift;

        my ( $vol, $dirs, $file ) = File::Spec->splitpath( $path );
        my @dirs = File::Spec->splitdir( $dirs );
        shift @dirs;    # remove inc

        $file =~ s{\.pm$}{};

        return join '::', grep { length } @dirs, $file;
    }

    # Test with multiple versions of perl
    sub dist_test {
        my $self = shift;

        my $make = $self->SUPER::dist_test( @_ );
        return $make unless $ENV{AUTHOR_TESTING} and $ENV{AUTHOR_TESTING} eq 'MSCHWERN';

        # Strip off all the whitespace at the end, we'll put our own in.
        $make =~ s{\s+\z}{\n};

        my @perls = qw( perl5.8.9 );

        for my $perl ( @perls ) {
            $make .= sprintf <<'END', $perl;
        cd $(DISTVNAME) && $(MAKE) clean && %s Makefile.PL && $(MAKE) test $(PASTHRU)
END
        }

        $make .= "\n";

        return $make;
    }
}
