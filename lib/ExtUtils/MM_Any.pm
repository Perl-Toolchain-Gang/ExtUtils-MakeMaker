package ExtUtils::MM_Any;

use strict;
use vars qw($VERSION @ISA);
$VERSION = 0.04;

use Config;
use File::Spec;


=head1 NAME

ExtUtils::MM_Any - Platform agnostic MM methods

=head1 SYNOPSIS

  FOR INTERNAL USE ONLY!

  package ExtUtils::MM_SomeOS;

  # Temporarily, you have to subclass both.  Put MM_Any first.
  require ExtUtils::MM_Any;
  require ExtUtils::MM_Unix;
  @ISA = qw(ExtUtils::MM_Any ExtUtils::Unix);

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>

ExtUtils::MM_Any is a superclass for the ExtUtils::MM_* set of
modules.  It contains methods which are either inherently
cross-platform or are written in a cross-platform manner.

Subclass off of ExtUtils::MM_Any I<and> ExtUtils::MM_Unix.  This is a
temporary solution.

B<THIS MAY BE TEMPORARY!>

=head1 Inherently Cross-Platform Methods

These are methods which are by their nature cross-platform and should
always be cross-platform.

=head2 File::Spec wrappers  B<DEPRECATED>

The following methods are deprecated wrappers around File::Spec
functions.  They exist from before File::Spec did and in fact are from
which File::Spec sprang.

With the exception of catfile(), they are all deprecated.  Please use
File::Spec directly.

=over 4

=item canonpath

=cut

sub canonpath {
    shift;
    return File::Spec->canonpath(@_);;
}

=item catdir

=cut

sub catdir {
    shift;
    return File::Spec->catdir(@_);
}

=item catfile

This catfile() fixes a bug in File::Spec <= 0.83.  Please use it inside
MakeMaker instead of using File::Spec's directly.

=cut

sub catfile {
    shift;
    # File::Spec <= 0.83 has a bug where the file part of catfile is
    # not canonicalized.
    return File::Spec->canonpath(File::Spec->catfile(@_));
}

=item curdir

=cut

my $Curdir = File::Spec->curdir;
sub curdir {
    return $Curdir;
}

=item file_name_is_absolute

=cut

sub file_name_is_absolute {
    shift;
    return File::Spec->file_name_is_absolute(@_);
}

=item path

=cut

sub path {
    return File::Spec->path();
}

=item rootdir

=cut

my $Rootdir = File::Spec->rootdir;
sub rootdir {
    return $Rootdir;
}

=item updir

=cut

my $Updir = File::Spec->updir;
sub updir {
    return $Updir;
}

=back

=head1 Thought To Be Cross-Platform Methods

These are methods which are thought to be cross-platform by virtue of
having been written in a way to avoid incompatibilities.

=over 4

=item manifypods

Defines targets and routines to translate the pods into manpages and
put them into the INST_* directories.

=cut

sub manifypods {
    my $self          = shift;

    my $POD2MAN_EXE_macro = $self->POD2MAN_EXE_macro();
    my $manifypods_target = $self->manifypods_target();

    return <<END_OF_TARGET;

# --- Begin manifypods section:
$POD2MAN_EXE_macro

$manifypods_target

# --- End manifypods section --- #

END_OF_TARGET

}


=item manifypods_target

  my $manifypods_target = $self->manifypods_target;

Generates the manifypods target.  This target generates man pages from
all POD files in MAN1PODS and MAN3PODS.

=cut

sub manifypods_target {
    my($self) = shift;

    my $man1pods      = '';
    my $man3pods      = '';
    my $dependencies  = '';

    # populate manXpods & dependencies:
    foreach my $name (keys %{$self->{MAN1PODS}}) {
        $man1pods     .= " \\\n\t  $name \\\n\t    $self->{MAN1PODS}->{$name}";
        $dependencies .= " \\\n\t$name";
    }

    foreach my $name (keys %{$self->{MAN3PODS}}) {
        $man3pods     .= " \\\n\t  $name \\\n\t    $self->{MAN3PODS}->{$name}";
        $dependencies .= " \\\n\t$name"
    }

    return <<END_OF_TARGET;
manifypods : pure_all $dependencies
	\$(NOECHO) \$(POD2MAN_EXE) --section=1 --perm_rw=\$(PERM_RW) $man1pods
	\$(NOECHO) \$(POD2MAN_EXE) --section=3 --perm_rw=\$(PERM_RW) $man3pods
END_OF_TARGET
}

=item POD2MAN_EXE_macro

  my $pod2man_exe_macro = $self->POD2MAN_EXE_macro

Returns a definition for the POD2MAN_EXE macro.  This is a program
which emulates the pod2man utility.  You can add more switches to the
command by simply appending them on the macro.

Typical usage:

    $(POD2MAN_EXE) --section=3 --perm_rw=$(PERM_RW) podfile man_page

=cut

sub POD2MAN_EXE_macro {
    my $self = shift;

# Need the trailing '--' so perl stops gobbling arguments and - happens
# to be an alternative end of line seperator on VMS so we quote it
    return <<'END_OF_DEF';
POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e "pod2man @ARGV" "--"
END_OF_DEF
}


=item test_via_harness

  my $command = $mm->test_via_harness($perl, $tests);

Returns a $command line which runs the given set of $tests with
Test::Harness and the given $perl.

Used on the t/*.t files.

=cut

sub test_via_harness {
    my($self, $perl, $tests) = @_;

    return qq{\t$perl "-MExtUtils::Command::MM" }.
           qq{"-e" "test_harness(\$(TEST_VERBOSE), '\$(INST_LIB)', '\$(INST_ARCHLIB)')" $tests\n};
}

=item test_via_script

  my $command = $mm->test_via_script($perl, $script);

Returns a $command line which just runs a single test without
Test::Harness.  No checks are done on the results, they're just
printed.

Used for test.pl, since they don't always follow Test::Harness
formatting.

=cut

sub test_via_script {
    my($self, $perl, $script) = @_;
    return qq{\t$perl "-I\$(INST_LIB)" "-I\$(INST_ARCHLIB)" $script\n};
}

=item libscan

  my $wanted = $self->libscan($path);

Takes a path to a file or dir and returns an empty string if we don't
want to include this file in the library.  Otherwise it returns the
the $path unchanged.

Mainly used to exclude RCS, CVS, and SCCS directories from
installation.

=cut

sub libscan {
    my($self,$path) = @_;
    my($dirs,$file) = (File::Spec->splitpath($path))[1,2];
    return '' if grep /^RCS|CVS|SCCS|\.svn$/, 
                     File::Spec->splitdir($dirs), $file;
    
    return $path;
}

=back

=head1 Abstract methods

Methods which cannot be made cross-platform and each subclass will
have to do their own implementation.

=over 4

=item perl_oneliner

  my $oneliner = $MM->perl_oneliner($perl_code, \@switches);

This will generate a perl one-liner safe for the particular platform
you're on based on the given $perl_code and @switches (a -e is
assumed) suitable for using in a make target.  It will use the proper
shell quoting and escapes.

$(PERLRUN) will be used as perl.

Any newlines in $perl_code will be escaped.  Leading and trailing
newlines will be stripped.  Makes this idiom much easier:

    my $code = $MM->perl_oneliner(<<'CODE', [...switches...]);
some code here
another line here
CODE

Usage might be something like:

    # an echo emulation
    $oneliner = $MM->perl_oneliner('print "Foo\n"');
    $make = '$oneliner > somefile';

All dollar signs must be doubled in the $perl_code if you expect them
to be interpreted normally, otherwise it will be considered a make
macro.  Also remember to quote make macros else it might be used as a
bareword.  For example:

    # Assign the value of the $(VERSION_FROM) make macro to $vf.
    $oneliner = $MM->perl_oneliner('$$vf = "$(VERSION_FROM)"');

Its currently very simple and may be expanded sometime in the figure
to include more flexible code and switches.


=item B<init_others>

    $MM->init_others();

Initializes the macro definitions used by tools_other() and places them
in the $MM object.

If there is no description, its the same as the parameter to
WriteMakefile() documented in ExtUtils::MakeMaker.

Defines at least these macros.

  Macro             Description

  NOOP              
  NOECHO                                        

  MAKEFILE
  FIRST_MAKEFILE
  MAKEFILE_OLD
  MAKE_APERL_FILE   File used by MAKE_APERL

  SHELL             Program used to run
                    shell commands

  RM_F              Remove a file 
  RM_RF             Remove a directory          
  TOUCH             Update a file's timestamp   
  TEST_F            Test for a file's existence 
  CP                Copy a file                 
  MV                Move a file                 
  CHMOD             Change permissions on a     
                    file

  UMASK_NULL        Nullify umask
  DEV_NULL          Supress all command output


=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix
and ExtUtils::MM_Win32.


=cut

1;
