package ExtUtils::MM_Cygwin;

use strict;
use vars qw($VERSION @ISA);

use Config;
use File::Spec;

require ExtUtils::MM_Any;
require ExtUtils::MM_Unix;
@ISA = qw( ExtUtils::MM_Any ExtUtils::MM_Unix );

$VERSION = 1.05;

sub cflags {
    my($self,$libperl)=@_;
    return $self->{CFLAGS} if $self->{CFLAGS};
    return '' unless $self->needs_linking();

    my $base = $self->SUPER::cflags($libperl);
    foreach (split /\n/, $base) {
        /^(\S*)\s*=\s*(\S*)$/ and $self->{$1} = $2;
    };
    $self->{CCFLAGS} .= " -DUSEIMPORTLIB" if ($Config{useshrplib} eq 'true');

    return $self->{CFLAGS} = qq{
CCFLAGS = $self->{CCFLAGS}
OPTIMIZE = $self->{OPTIMIZE}
PERLTYPE = $self->{PERLTYPE}
};

}


# Cygwin uses Foo.Bar.3 man page styles.
sub replace_manpage_separator {
    my($self, $man) = @_;
    $man =~ s{/+}{.}g;
    return $man;
}

sub perl_archive {
    if ($Config{useshrplib} eq 'true') {
        my $libperl = '$(PERL_INC)' .'/'. "$Config{libperl}";
        if( $] >= 5.007 ) {
            $libperl =~ s/a$/dll.a/;
        }
        return $libperl;
    } else {
        return '$(PERL_INC)' .'/'. ("$Config{libperl}" or "libperl.a");
    }
}

1;
__END__

=head1 NAME

ExtUtils::MM_Cygwin - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_Cygwin; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided there.

=over 4

=item cflags

if configured for dynamic loading, triggers #define EXT in EXTERN.h

=item init_dirscan

replaces strings '::' with '.' in MAN*POD man page names

=item perl_archive

points to libperl.a

=back

=cut

