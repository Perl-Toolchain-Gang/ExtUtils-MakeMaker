# A template for Makefile.PL.
# - Set the $PACKAGE variable to the name of your module.
# - Set $LAST_API_CHANGE to reflect the last version you changed the API 
#   of your module.
# - Fill in your dependencies in PREREQ_PM
# Alternatively, you can say the hell with this and use h2xs.

use 5.00503;

use lib qw(lib);    # build ourself with ourself
use ExtUtils::MakeMaker;

$PACKAGE = 'ExtUtils::MakeMaker';
($PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;
$LAST_API_CHANGE = 5.50;

eval "require $PACKAGE";

unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

# Test::Harnesses prior to 2.00 shoved all of @INC onto the command line
# when a test had -T.  This made it too long.  So we need a Test::Harness
# > 2.00 on VMS for t/testlib.t
my %prereq = ( File::Spec         => 0.8,
               File::Basename     => 0,
               DirHandle          => 0,
             );
$prereq{'Test::Harness'} = 2.00 if $^O eq 'VMS';


WriteMakefile(
    NAME            => $PACKAGE,
    VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
    PREREQ_PM       => \%prereq,
    INSTALLDIRS     => 'perl',
    EXE_FILES       => [qw(bin/instmodsh)],
);


{
    package MY;

    use File::Spec;

    my($lib, $tlib);
    BEGIN { 
        $lib  = File::Spec->rel2abs('lib/'); 
        $tlib = File::Spec->rel2abs('t/lib/');
    }

    # Make sure PERLRUN uses the MakeMaker about to be installed
    # and not the currently installed one.
    sub init_PERL {
        my($self) = shift;
        $self->SUPER::init_PERL;
        $self->{PERLRUN} .= qq{ "-I$lib"};
        $self->{FULLPERLRUN} .= qq{ "-I$lib"};
    }

    use Config;
    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        if( $ENV{PERL_TEST_ALL} ) {
            push @perls, 
              map "PERL5LIB=$lib$Config{path_sep}$tlib /usr/local/bin/$_",
                'perl5.5.3';

            push @perls, map "PERL5LIB=$lib /usr/local/bin/$_", 
              qw(perl5.6.0
                 perl5.6.1
                 perl
                 perl5.8.0
                 perl5.8.0-ithreads
                 bleadperl
                );
        }

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}
