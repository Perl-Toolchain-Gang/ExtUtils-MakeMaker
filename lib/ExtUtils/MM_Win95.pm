package ExtUtils::MM_Win95;

use vars qw($VERSION @ISA);
$VERSION = 0.02;

require ExtUtils::MM_Win32;
@ISA = qw(ExtUtils::MM_Win32);

use Config;
my $DMAKE = 1 if $Config{'make'} =~ /^dmake/i;
my $NMAKE = 1 if $Config{'make'} =~ /^nmake/i;


=head1 NAME

ExtUtils::MM_Win95 - method to customize MakeMaker for Win9X

=head1 SYNOPSIS

  You should not be using this module directly.

=head1 DESCRIPTION

This is a subclass of ExtUtils::MM_Win32 containing changes necessary
to get MakeMaker playing nice with command.com and other Win9Xisms.

=head2 Overriden methods

Most of these make up for limitations in the Win9x command shell.

=over 4

=item dist_test

command.com has no &&, so we must chdir at the top of the target and
chdir back at the end.

=cut

sub dist_test {
    my($self) = shift;
    return q{
disttest : distdir
	cd $(DISTVNAME)
	$(ABSPERLRUN) Makefile.PL
	$(MAKE) $(PASTHRU)
	$(MAKE) test $(PASTHRU)
	cd ..
};
}

=item subdir_x

The && problem.

Also, dmake has an odd way of making a command series silent.

=cut

sub subdir_x {
    my($self, $subdir) = @_;

    # Win-9x has nasty problem in command.com that can't cope with
    # &&.  Also, Dmake has an odd way of making a commandseries silent:
    if ($DMAKE) {
      return sprintf <<'EOT', $subdir;

subdirs ::
@[
	cd %s
	$(MAKE) all $(PASTHRU)
	cd ..
]
EOT
    }
    else {
        return sprintf <<'EOT', $subdir;

subdirs ::
	$(NOECHO)cd %s
	$(NOECHO)$(MAKE) all $(PASTHRU)
	$(NOECHO)cd ..
EOT
    }
}

=item xs_c

The && problem.

=cut

sub xs_c {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs.c:
	$(PERLRUN) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.c
	'
}


=item xs_cpp

The && problem

=cut

sub xs_cpp {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs.cpp:
	$(PERLRUN) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.cpp
	';
}

=item xs_o 

The && problem.

=cut

sub xs_o {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs$(OBJ_EXT):
	$(PERLRUN) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) $*.c
	';
}

1;
