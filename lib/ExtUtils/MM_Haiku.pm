package ExtUtils::MM_Haiku;

use strict;
use warnings;

=head1 NAME

ExtUtils::MM_Haiku - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_Haiku;    # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=over 4

=cut

use ExtUtils::MakeMaker::Config;
use File::Spec;
use ExtUtils::MM_Unix;

our @ISA = qw( ExtUtils::MM_Unix );
our $VERSION = '7.63_02';
$VERSION =~ tr/_//d;


sub os_flavor {
    return('Haiku');
}

sub init_main {
    my $self = shift;

    # switch to vendor directories if requested.
    if ($ENV{'HAIKU_USE_VENDOR_DIRECTORIES'}) {
        $self->{INSTALLDIRS} ||= 'vendor';
    }

    $self->SUPER::init_main();
}

sub init_others {
    my $self = shift;

    $self->SUPER::init_others();

    # Don't use run-time paths for libraries required by dynamic
    # modules on Haiku, as that wouldn't work should a library be moved
    # (for instance because the package has been activated somewhere else).
    $self->{LD_RUN_PATH} = "";

    return;
}

1;
__END__

