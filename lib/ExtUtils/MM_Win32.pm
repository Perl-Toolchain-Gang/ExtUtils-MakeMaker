package ExtUtils::MM_Win32;


=head1 NAME

ExtUtils::MM_Win32 - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_Win32; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=over 4

=cut 

use Config;
use File::Basename;
use File::Spec;
use ExtUtils::MakeMaker qw( neatvalue );

use vars qw(@ISA $VERSION $BORLAND $GCC $DMAKE $NMAKE);

require ExtUtils::MM_Any;
require ExtUtils::MM_Unix;
@ISA = qw( ExtUtils::MM_Any ExtUtils::MM_Unix );
$VERSION = '1.06';

$ENV{EMXSHELL} = 'sh'; # to run `commands`

$BORLAND = 1 if $Config{'cc'} =~ /^bcc/i;
$GCC     = 1 if $Config{'cc'} =~ /^gcc/i;
$DMAKE = 1 if $Config{'make'} =~ /^dmake/i;
$NMAKE = 1 if $Config{'make'} =~ /^nmake/i;


=head2 Overridden methods

=over 4

=item B<dlsyms>

=cut

sub dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($funclist) = $attribs{FUNCLIST} || $self->{FUNCLIST} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     q!	$(PERLRUN) -MExtUtils::Mksymlists \\
     -e "Mksymlists('NAME'=>\"!, $self->{NAME},
     q!\", 'DLBASE' => '!,$self->{DLBASE},
     # The above two lines quoted differently to work around
     # a bug in the 4DOS/4NT command line interpreter.  The visible
     # result of the bug was files named q('extension_name',) *with the
     # single quotes and the comma* in the extension build directories.
     q!', 'DL_FUNCS' => !,neatvalue($funcs),
     q!, 'FUNCLIST' => !,neatvalue($funclist),
     q!, 'IMPORTS' => !,neatvalue($imports),
     q!, 'DL_VARS' => !, neatvalue($vars), q!);"
!);
    }
    join('',@m);
}

=item replace_manpage_separator

Changes the path separator with .

=cut

sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,.,g;
    $man;
}


=item B<maybe_command>

Since Windows has nothing as simple as an executable bit, we check the
file extension.

The PATHEXT env variable will be used to get a list of extensions that
might indicate a command, otherwise .com, .exe, .bat and .cmd will be
used by default.

=cut

sub maybe_command {
    my($self,$file) = @_;
    my @e = exists($ENV{'PATHEXT'})
          ? split(/;/, $ENV{PATHEXT})
	  : qw(.com .exe .bat .cmd);
    my $e = '';
    for (@e) { $e .= "\Q$_\E|" }
    chop $e;
    # see if file ends in one of the known extensions
    if ($file =~ /($e)$/i) {
	return $file if -e $file;
    }
    else {
	for (@e) {
	    return "$file$_" if -e "$file$_";
	}
    }
    return;
}


=item B<find_tests>

The Win9x shell does not expand globs and I'll play it safe and assume
other Windows variants don't either.

So we do it for them.

=cut

sub find_tests {
    return join(' ', <t\\*.t>);
}


=item B<init_EXISTS_EXT>

Using \.exists

=cut

sub init_EXISTS_EXT {
    my($self) = shift;

    $self->{EXISTS_EXT} = '\.exists';
    return 1;
}

=item B<init_others>

Override some of the Unix specific commands with portable
ExtUtils::Command ones.

Also provide defaults for LD and AR in case the %Config values aren't
set.

LDLOADLIBS's default is changed to $Config{libs}.

Adjustments are made for Borland's quirks needing -L to come first.

=cut

sub init_others {
    my ($self) = @_;

    $self->{'TOUCH'}    ||= '$(PERLRUN) -MExtUtils::Command -e touch';
    $self->{'CHMOD'}    ||= '$(PERLRUN) -MExtUtils::Command -e chmod'; 
    $self->{'CP'}       ||= '$(PERLRUN) -MExtUtils::Command -e cp';
    $self->{'RM_F'}     ||= '$(PERLRUN) -MExtUtils::Command -e rm_f';
    $self->{'RM_RF'}    ||= '$(PERLRUN) -MExtUtils::Command -e rm_rf';
    $self->{'MV'}       ||= '$(PERLRUN) -MExtUtils::Command -e mv';
    $self->{'NOOP'}     ||= 'rem';
    $self->{'TEST_F'}   ||= '$(PERLRUN) -MExtUtils::Command -e test_f';
    $self->{'DEV_NULL'} ||= '> NUL';

    # technically speaking, these should be in init_main()
    $self->{'LD'}     ||= $Config{'ld'} || 'link';
    $self->{'AR'}     ||= $Config{'ar'} || 'lib';

    $self->SUPER::init_others;

    $self->{'LDLOADLIBS'} ||= $Config{'libs'};
    # -Lfoo must come first for Borland, so we put it in LDDLFLAGS
    if ($BORLAND) {
        my $libs = $self->{'LDLOADLIBS'};
        my $libpath = '';
        while ($libs =~ s/(?:^|\s)(("?)-L.+?\2)(?:\s|$)/ /) {
            $libpath .= ' ' if length $libpath;
            $libpath .= $1;
        }
        $self->{'LDLOADLIBS'} = $libs;
        $self->{'LDDLFLAGS'} ||= $Config{'lddlflags'};
        $self->{'LDDLFLAGS'} .= " $libpath";
    }

    return 1;
}


=item constants (o)

Initializes lots of constants and .SUFFIXES and .PHONY

=cut

sub constants {
    my($self) = @_;
    my(@m,$tmp);

    for $tmp (qw/
              AR_STATIC_ARGS NAME DISTNAME NAME_SYM VERSION
              VERSION_SYM XS_VERSION 
              INST_BIN INST_LIB INST_ARCHLIB INST_SCRIPT 
              EXISTS_EXT
              INSTALLDIRS
              PREFIX          SITEPREFIX      VENDORPREFIX
              INSTALLPRIVLIB  INSTALLSITELIB  INSTALLVENDORLIB
              INSTALLARCHLIB  INSTALLSITEARCH INSTALLVENDORARCH
              INSTALLBIN      INSTALLSITEBIN  INSTALLVENDORBIN  INSTALLSCRIPT 
              PERL_LIB        PERL_ARCHLIB 
              SITELIBEXP      SITEARCHEXP 
              LIBPERL_A MYEXTLIB
              FIRST_MAKEFILE MAKEFILE MAKEFILE_OLD MAKE_APERL_FILE 
              PERLMAINCC PERL_SRC
              PERL_INC PERL FULLPERL PERLRUN FULLPERLRUN PERLRUNINST 
              FULLPERLRUNINST ABSPERL ABSPERLRUN ABSPERLRUNINST
              FULL_AR PERL_CORE
              PERM_RW PERM_RWX
              / ) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }

    push @m, qq{
VERSION_MACRO = VERSION
DEFINE_VERSION = -D\$(VERSION_MACRO)=\\\"\$(VERSION)\\\"
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D\$(XS_VERSION_MACRO)=\\\"\$(XS_VERSION)\\\"
};

    push @m, qq{
MAKEMAKER = $INC{'ExtUtils/MakeMaker.pm'}
MM_VERSION = $ExtUtils::MakeMaker::VERSION
};

    push @m, q{
# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
};

    for $tmp (qw/
	      FULLEXT BASEEXT PARENT_NAME DLBASE VERSION_FROM INC DEFINE OBJECT
	      LDFROM LINKTYPE
	      /	) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }

    push @m, "
# Handy lists of source code files:
XS_FILES= ".join(" \\\n\t", sort keys %{$self->{XS}})."
C_FILES = ".join(" \\\n\t", @{$self->{C}})."
O_FILES = ".join(" \\\n\t", @{$self->{O_FILES}})."
H_FILES = ".join(" \\\n\t", @{$self->{H}})."
MAN1PODS = ".join(" \\\n\t", sort keys %{$self->{MAN1PODS}})."
MAN3PODS = ".join(" \\\n\t", sort keys %{$self->{MAN3PODS}})."
";

    for $tmp (qw/
	      INST_MAN1DIR  MAN1EXT 
              INSTALLMAN1DIR INSTALLSITEMAN1DIR INSTALLVENDORMAN1DIR
	      INST_MAN3DIR  MAN3EXT
              INSTALLMAN3DIR INSTALLSITEMAN3DIR INSTALLVENDORMAN3DIR
	      /) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }

    push @m, qq{
.USESHELL :
} if $DMAKE;

    push @m, q{
.NO_CONFIG_REC: Makefile
} if $ENV{CLEARCASE_ROOT};

    # why not q{} ? -- emacs
    push @m, qq{
# work around a famous dec-osf make(1) feature(?):
makemakerdflt: all

.SUFFIXES: .xs .c .C .cpp .cxx .cc \$(OBJ_EXT)

# Nick wanted to get rid of .PRECIOUS. I don't remember why. I seem to 
# recall, that some make implementations will delete the Makefile when we 
# rebuild it. Because we call false(1) when we rebuild it. So make(1) is 
# not completely wrong when it does so. Our milage may vary.
# .PRECIOUS: Makefile    # seems to be not necessary anymore

.PHONY: all config static dynamic test linkext manifest

# Where is the Config information that we are using/depend on
CONFIGDEP = \$(PERL_ARCHLIB)\\Config.pm \$(PERL_INC)\\config.h
};

    my @parentdir = split(/::/, $self->{PARENT_NAME});
    push @m, q{
# Where to put things:
INST_LIBDIR      = }. File::Spec->catdir('$(INST_LIB)',@parentdir)        .q{
INST_ARCHLIBDIR  = }. File::Spec->catdir('$(INST_ARCHLIB)',@parentdir)    .q{

INST_AUTODIR     = }. File::Spec->catdir('$(INST_LIB)','auto','$(FULLEXT)')       .q{
INST_ARCHAUTODIR = }. File::Spec->catdir('$(INST_ARCHLIB)','auto','$(FULLEXT)')   .q{
};

    if ($self->has_link_code()) {
	push @m, '
INST_STATIC  = $(INST_ARCHAUTODIR)\$(BASEEXT)$(LIB_EXT)
INST_DYNAMIC = $(INST_ARCHAUTODIR)\$(DLBASE).$(DLEXT)
INST_BOOT    = $(INST_ARCHAUTODIR)\$(BASEEXT).bs
';
    } else {
	push @m, '
INST_STATIC  =
INST_DYNAMIC =
INST_BOOT    =
';
    }

    $tmp = $self->export_list;
    push @m, "
EXPORT_LIST = $tmp
";
    $tmp = $self->perl_archive;
    push @m, "
PERL_ARCHIVE = $tmp
";

    push @m, q{
TO_INST_PM = }.join(" \\\n\t", sort keys %{$self->{PM}}).q{

PM_TO_BLIB = }.join(" \\\n\t", %{$self->{PM}}).q{
};

    join('',@m);
}


=item static_lib (o)

Defines how to produce the *.a (or equivalent) files.

Most of this is copied from MM_Unix except for the AR bits.

=cut

sub static_lib {
    my($self) = @_;
    return '' unless $self->has_link_code;

    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(EXISTS_EXT)
	$(RM_RF) $@
END

    # If this extension has its own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, <<'MAKE_FRAG' if $self->{MYEXTLIB};
	$(CP) $(MYEXTLIB) $@
MAKE_FRAG

    push @m,
q{	$(AR) }.($BORLAND ? '$@ $(OBJECT:^"+")'
			  : ($GCC ? '-ru $@ $(OBJECT)'
			          : '-out:$@ $(OBJECT)')).q{
	$(CHMOD) $(PERM_RWX) $@
	$(NOECHO) echo "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)\extralibs.ld
};

    # Old mechanism - still available:
    push @m, <<'MAKE_FRAG' if $self->{PERL_SRC} && $self->{EXTRALIBS};
	$(NOECHO) echo "$(EXTRALIBS)" >> $(PERL_SRC)\ext.libs
MAKE_FRAG

    push @m, "\n", $self->dir_target('$(INST_ARCHAUTODIR)');
    join('', @m);
}


=item dynamic_lib (o)

Defines how to produce the *.so (or equivalent) files.

=cut

sub dynamic_lib {
    my($self, %attribs) = @_;
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my($otherldflags) = $attribs{OTHERLDFLAGS} || ($BORLAND ? 'c0d32.obj': '');
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my($ldfrom) = '$(LDFROM)';
    my(@m);

# one thing for GCC/Mingw32:
# we try to overcome non-relocateable-DLL problems by generating
#    a (hopefully unique) image-base from the dll's name
# -- BKS, 10-19-1999
    if ($GCC) { 
	my $dllname = $self->{BASEEXT} . "." . $self->{DLEXT};
	$dllname =~ /(....)(.{0,4})/;
	my $baseaddr = unpack("n", $1 ^ $2);
	$otherldflags .= sprintf("-Wl,--image-base,0x%x0000 ", $baseaddr);
    }

    push(@m,'
# This section creates the dynamically loadable $(INST_DYNAMIC)
# from $(OBJECT) and possibly $(MYEXTLIB).
OTHERLDFLAGS = '.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)$(EXISTS_EXT) $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
');
    if ($GCC) {
      push(@m,  
       q{	dlltool --def $(EXPORT_LIST) --output-exp dll.exp
	$(LD) -o $@ -Wl,--base-file -Wl,dll.base $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) dll.exp
	dlltool --def $(EXPORT_LIST) --base-file dll.base --output-exp dll.exp
	$(LD) -o $@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) dll.exp });
    } elsif ($BORLAND) {
      push(@m,
       q{	$(LD) $(LDDLFLAGS) $(OTHERLDFLAGS) }.$ldfrom.q{,$@,,}
       .($DMAKE ? q{$(PERL_ARCHIVE:s,/,\,) $(LDLOADLIBS:s,/,\,) }
		 .q{$(MYEXTLIB:s,/,\,),$(EXPORT_LIST:s,/,\,)}
		: q{$(subst /,\,$(PERL_ARCHIVE)) $(subst /,\,$(LDLOADLIBS)) }
		 .q{$(subst /,\,$(MYEXTLIB)),$(subst /,\,$(EXPORT_LIST))})
       .q{,$(RESFILES)});
    } else {	# VC
      push(@m,
       q{	$(LD) -out:$@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) }
      .q{$(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) -def:$(EXPORT_LIST)});
    }
    push @m, '
	$(CHMOD) $(PERM_RWX) $@
';

    push @m, $self->dir_target('$(INST_ARCHAUTODIR)');
    join('',@m);
}

sub clean
{
    my ($self) = shift;
    my $s = $self->SUPER::clean(@_);
    my $clean = $GCC ? 'dll.base dll.exp' : '*.pdb';
    $s .= <<END;
clean ::
	-\$(RM_F) $clean

END
    return $s;
}



sub perl_archive
{
    my ($self) = @_;
    return '$(PERL_INC)\\'.$Config{'libperl'};
}

sub export_list
{
 my ($self) = @_;
 return "$self->{BASEEXT}.def";
}


=item perl_script

Takes one argument, a file name, and returns the file name, if the
argument is likely to be a perl script. On MM_Unix this is true for
any ordinary, readable file.

=cut

sub perl_script {
    my($self,$file) = @_;
    return $file if -r $file && -f _;
    return "$file.pl" if -r "$file.pl" && -f _;
    return "$file.bat" if -r "$file.bat" && -f _;
    return;
}

=item pm_to_blib

Defines target that copies all files in the hash PM to their
destination and autosplits them. See L<ExtUtils::Install/DESCRIPTION>

=cut

sub pm_to_blib {
    my $self = shift;
    my($autodir) = File::Spec->catdir('$(INST_LIB)','auto');
    return q{
pm_to_blib: $(TO_INST_PM)
	}.$self->{NOECHO}.q{$(PERLRUNINST) -MExtUtils::Install \
        -e "pm_to_blib(}.
	($NMAKE ? 'qw[ <<pmfiles.dat ],'
	        : $DMAKE ? 'qw[ $(mktmp,pmfiles.dat $(PM_TO_BLIB:s,\\,\\\\,)\n) ],'
			 : '{ qw[$(PM_TO_BLIB)] },'
	 ).q{'}.$autodir.q{','$(PM_FILTER)')"
}. ($NMAKE ? q{
$(PM_TO_BLIB)
<<
	} : '') . "\t".$self->{NOECHO}.q{$(TOUCH) $@
};
}


=item tool_autosplit (override)

Use Win32 quoting on command line.

=cut

sub tool_autosplit{
    my($self, %attribs) = @_;
    my($asl) = "";
    $asl = "\$AutoSplit::Maxlen=$attribs{MAXLEN};" if $attribs{MAXLEN};
    q{
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(PERLRUN) -MAutoSplit }.$asl.q{ -e "autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1);"
};
}


=item xs_o (o)

Defines suffix rules to go from XS to object files directly. This is
only intended for broken make implementations.

=cut

sub xs_o {	# many makes are too dumb to use xs_c then c_o
    my($self) = shift;
    return ''
}

=item top_targets (o)

Defines the targets all, subdirs, config, and O_FILES

=cut

sub top_targets {
# --- Target Sections ---

    my($self) = shift;
    my(@m);

    push @m, '
all :: pure_all
	'.$self->{NOECHO}.'$(NOOP)
' 
	  unless $self->{SKIPHASH}{'all'};
    
    push @m, '
pure_all :: config pm_to_blib subdirs linkext
	'.$self->{NOECHO}.'$(NOOP)

subdirs :: $(MYEXTLIB)
	'.$self->{NOECHO}.'$(NOOP)

config :: $(MAKEFILE) $(INST_LIBDIR)$(EXISTS_EXT)
	'.$self->{NOECHO}.'$(NOOP)

config :: $(INST_ARCHAUTODIR)$(EXISTS_EXT)
	'.$self->{NOECHO}.'$(NOOP)

config :: $(INST_AUTODIR)$(EXISTS_EXT)
	'.$self->{NOECHO}.'$(NOOP)
';

    push @m, $self->dir_target(qw[$(INST_AUTODIR) $(INST_LIBDIR) $(INST_ARCHAUTODIR)]);

    if (%{$self->{MAN1PODS}}) {
	push @m, qq[
config :: \$(INST_MAN1DIR)\$(EXISTS_EXT)
	$self->{NOECHO}\$(NOOP)

];
	push @m, $self->dir_target(qw[$(INST_MAN1DIR)]);
    }
    if (%{$self->{MAN3PODS}}) {
	push @m, qq[
config :: \$(INST_MAN3DIR)\$(EXISTS_EXT)
	$self->{NOECHO}\$(NOOP)

];
	push @m, $self->dir_target(qw[$(INST_MAN3DIR)]);
    }

    push @m, '
$(O_FILES): $(H_FILES)
' if @{$self->{O_FILES} || []} && @{$self->{H} || []};

    push @m, q{
help:
	perldoc ExtUtils::MakeMaker
};

    join('',@m);
}


=item pasthru (o)

Defines the string that is passed to recursive make calls in
subdirectories.

=cut

sub pasthru {
    my($self) = shift;
    return "PASTHRU = " . ($NMAKE ? "-nologo" : "");
}


=item perl_oneliner (o)

These are based on what command.com does on Win98.  They may be wrong
for other Windows shells, I don't know.

=cut

sub perl_oneliner {
    my($self, $cmd, $switches) = @_;
    $switches = [] unless defined $switches;

    # Strip leading and trailing newlines
    $cmd =~ s{^\n+}{};
    $cmd =~ s{\n+$}{};

    # Escape newlines
    $cmd =~ s{\n}{\\\n}g;

    # I don't know if this is correct, but it seems to work on
    # Win98's command.com
    $cmd =~ s{"}{\\"}g;

    # Backwacks are normally literal but \" is an escaped quote and
    # \\ is an escaped backwack.
    $cmd =~ s{\\\\}{\\\\\\\\}g;
    $cmd =~ s{\\"}{\\\\"}g;

    $switches = join ' ', @$switches;    

    return qq{\$(PERLRUN) $switches -e "$cmd"};
}


1;
__END__

=back

=cut 


