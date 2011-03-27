package my::bundles;

use strict;
use warnings;


=head1 NAME

my::bundles - Load all the modules bundled with MakeMaker

=head1 SYNOPSIS

    use lib ".";
    use my::bundles;

    my::bundles::copy_bundles($src, $dest);

=head1 DESCRIPTION

Include all the modules bundled with MakeMaker in @INC so
ExtUtils::MakeMaker will load.

This is for bootstrapping the process of deciding how much of the
bundles we need.

copy_bundles() copies the contents of each bundle, if necessary, into
inc/ as a flattened module directory that MakeMaker can install.

=cut

require lib;
my $bundle_dir = "bundled";

use File::Path;

my %special_dist = (
    "Scalar-List-Utils" => sub {
        # Special case for Scalar::Util, never override the XS version with a
        # pure Perl version.  Just check that it's there.
        my $installed = find_installed("Scalar/Util.pm");
        return if $installed;

        my $inc_version = MM->parse_version("$bundle_dir/Scalar-List-Utils/Scalar/Util.pm");
        print "Using included version of Scalar::Util ($inc_version) because it is not already installed.\n";
        return 1;
    }
);


sub import {
    opendir my $dh, $bundle_dir or die "Can't open bundles directory: $!";
    my @bundles = map { "$bundle_dir/$_" } grep !/^\./, readdir $dh;
    lib->import(@bundles);
}


sub copy_bundles {
    my($src, $dest) = @_;

    require File::Copy::Recursive;

    rmtree $dest;
    mkpath $dest;

    opendir my $bundle_dh, $src or die $!;
    for my $dist (grep !/^\./, readdir $bundle_dh) {
        my $should_use = $special_dist{$dist} || \&should_use_dist;

        next unless $should_use->($dist);

        File::Copy::Recursive::rcopy_glob("$src/$dist/*", $dest) or
          die "Can't copy $src/$dist/* to $dest";
    }
}


sub should_use_dist {
    my $dist = shift;

    my $module = $dist;
    $module =~ s{-}{::}g;

    my $pm_file = $dist;
    $pm_file =~ s{-}{/}g;
    $pm_file .= ".pm";

    my $installed = find_installed( $pm_file );

    require ExtUtils::MakeMaker;

    # Shut up "isn't numeric" warning on X.Y_Z versions.
    my $installed_version = $installed ? MM->parse_version( $installed ) : 0;
    my $inc_version       = MM->parse_version( "$bundle_dir/$dist/$pm_file" );

    $installed_version = cleanup_version($installed_version);
    $inc_version       = cleanup_version($inc_version);

    if ( !$installed ) {
        print qq{Using included version of $module ($inc_version) because it is not already installed.\n};
        return 1;
    }
    elsif ( $installed_version < $inc_version ) {
        print qq{Using included version of $module ($inc_version) as it is newer than the installed version ($installed_version).\n};
        return 1;
    }
    else {
        return 0;
    }
}


sub find_installed {
    my $file = shift;

    for my $inc (grep !m{^\Q$bundle_dir/}, @INC) {
        my $path = File::Spec->catfile( $inc, $file );
        return $path if -r $path;
    }

    return;
}


# Remove alphas and make it into a number which can be compared.
sub cleanup_version {
    my $version = shift;
    $version =~ s{_}{};

    return $version;
}

1;
