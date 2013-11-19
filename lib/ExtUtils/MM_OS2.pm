package ExtUtils::MM_OS2;

use strict;

use ExtUtils::MakeMaker qw(neatvalue);
use File::Spec;

our $VERSION = '6.83_04';

require ExtUtils::MM_Any;
require ExtUtils::MM_Unix;
our @ISA = qw(ExtUtils::MM_Any ExtUtils::MM_Unix);

=pod

=head1 NAME

ExtUtils::MM_OS2 - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_OS2; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided
there. This package overrides the implementation of these methods, not
the semantics.

=head1 METHODS

=over 4

=item init_dist

Define TO_UNIX to convert OS2 linefeeds to Unix style.

=cut

sub init_dist {
    my($self) = @_;

    $self->{TO_UNIX} ||= <<'MAKE_TEXT';
$(NOECHO) $(TEST_F) tmp.zip && $(RM_F) tmp.zip; $(ZIP) -ll -mr tmp.zip $(DISTVNAME) && unzip -o tmp.zip && $(RM_F) tmp.zip
MAKE_TEXT

    $self->SUPER::init_dist;
}

sub dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($funclist) = $attribs{FUNCLIST} || $self->{FUNCLIST} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);
    (my $boot = $self->{NAME}) =~ s/:/_/g;

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     '	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e \'use ExtUtils::Mksymlists; \\
     Mksymlists("NAME" => "$(NAME)", "DLBASE" => "$(DLBASE)", ',
     '"VERSION" => "$(VERSION)", "DISTNAME" => "$(DISTNAME)", ',
     '"INSTALLDIRS" => "$(INSTALLDIRS)", ',
     '"DL_FUNCS" => ',neatvalue($funcs),
     ', "FUNCLIST" => ',neatvalue($funclist),
     ', "IMPORTS" => ',neatvalue($imports),
     ', "DL_VARS" => ', neatvalue($vars), ');\'
');
    }
    if ($self->{IMPORTS} && %{$self->{IMPORTS}}) {
	# Make import files (needed for static build)
	-d 'tmp_imp' or mkdir 'tmp_imp', 0777 or die "Can't mkdir tmp_imp";
	open my $imp, '>', 'tmpimp.imp' or die "Can't open tmpimp.imp";
	while (my($name, $exp) = each %{$self->{IMPORTS}}) {
	    my ($lib, $id) = ($exp =~ /(.*)\.(.*)/) or die "Malformed IMPORT `$exp'";
	    print $imp "$name $lib $id ?\n";
	}
	close $imp or die "Can't close tmpimp.imp";
	# print "emximp -o tmpimp$Config::Config{lib_ext} tmpimp.imp\n";
	system "emximp -o tmpimp$Config::Config{lib_ext} tmpimp.imp"
	    and die "Cannot make import library: $!, \$?=$?";
	# May be running under miniperl, so have no glob...
	eval { unlink <tmp_imp/*>; 1 } or system "rm tmp_imp/*";
	system "cd tmp_imp; $Config::Config{ar} x ../tmpimp$Config::Config{lib_ext}"
	    and die "Cannot extract import objects: $!, \$?=$?";
    }
    join('',@m);
}

=item static_lib_template

Defines how to produce any *.lib (or equivalent) files.

=cut

sub static_lib_template
{
    my ($self, $target, $deps, $src, $fixtures, $closures) = @_;

    my @m = $self->ExtUtils::MM_Unix::static_lib_template($target, $deps, $src, $fixtures, $closures);
    push @m, q{	$(AR) $(AR_STATIC_ARGS) $@ tmp_imp/* && $(RANLIB) $@};

    return @m;
}

sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,.,g;
    $man;
}

sub maybe_command {
    my($self,$file) = @_;
    $file =~ s,[/\\]+,/,g;
    return $file if -x $file && ! -d _;
    return "$file.exe" if -x "$file.exe" && ! -d _;
    return "$file.cmd" if -x "$file.cmd" && ! -d _;
    return;
}

=item init_linker

=cut

sub init_linker {
    my $self = shift;

    $self->{PERL_ARCHIVE} = "\$(PERL_INC)/libperl\$(LIB_EXT)";

    $self->{PERL_ARCHIVE_AFTER} = $OS2::is_aout
      ? ''
      : '$(PERL_INC)/libperl_override$(LIB_EXT)';
    $self->{EXPORT_LIST} = '$(BASEEXT).def';
}

=item os_flavor

OS/2 is OS/2

=cut

sub os_flavor {
    return('OS/2');
}

=back

=cut

1;
