package ExtUtils::MM_Any;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

use Config;
use File::Spec;


=head1 NAME

ExtUtils::MM_Any - Platform agnostic MM methods

=head1 SYNOPSIS

  FOR INTERNAL USE ONLY!

  package ExtUtils::MM_SomeOS;

  # For the moment, you get at MM_Any via MM_Unix
  require ExtUtils::MM_Unix;
  @ISA = qw(ExtUtils::MM_Unix);

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>

ExtUtils::MM_Any is a superclass for the ExtUtils::MM_* set of
modules.  It contains methods which are either inherently
cross-platform or are written in a cross-platform manner.

B<THIS MAY BE TEMPORARY!> Do not subclass or use ExtUtils::MM_Any
directly.  Instead, subclass from ExtUtils::MM_Unix.

=head1 Inherently Cross-Platform Methods

These are methods which are by their nature cross-platform and should
always be cross-platform.

=head2 File::Spec wrappers  B<DEPRECATED>

The following methods are deprecated wrappers around File::Spec
functions.  They exist from before File::Spec did and in fact are from
which File::Spec sprang.

They are all deprecated.  Please use File::Spec directly.

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

=cut

sub catfile {
    shift;
    return File::Spec->catdir(@_);
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

=item htmlifypods

  $htmlifypods_target = $mm->htmlifypods;

Defines targets and routines to translate the pods into HTML manpages
using pod2html and put them into the INST_HTMLLIBDIR and
INST_HTMLSCRIPTDIR directories.

$(POD2HTML_EXE) and $(POD2HTML) are defined and the htmlifypods target
built.

=cut

sub htmlifypods {
    my $self = shift;
    return "\nhtmlifypods : pure_all\n\t$self->{NOECHO}\$(NOOP)\n" unless
      %{$self->{HTMLLIBPODS}} || %{$self->{HTMLSCRIPTPODS}};
    my($dist);
    my($pod2html_exe);
    if (defined $self->{PERL_SRC}) {
        $pod2html_exe = File::Spec->catfile($self->{PERL_SRC},'pod',
                                            'pod2html');
    } 
    else {
	$pod2html_exe = File::Spec->catfile($Config{scriptdirexp},'pod2html');
    }
    unless ($pod2html_exe = $self->perl_script($pod2html_exe)) {
	# No pod2html but some HTMLxxxPODS to be installed
	print <<END;

Warning: I could not locate your pod2html program. Please make sure,
         your pod2html program is in your PATH before you execute 'make'

END
        $pod2html_exe = "-S pod2html";
    }

    my $m = sprintf <<'MAKE_TEXT', $pod2html_exe, $self->{MAKEFILE};
POD2HTML_EXE = %s
POD2HTML = \$(PERLRUN) "-we" "use File::Basename; use File::Path q(mkpath);" \\
-e "%%m=@ARGV;while (($p,$h) = each %%m){" \\
-e "  next if -e $$h && -M $$h < -M $$p && -M $$h < -M '%s';" \\
-e "  print qq(Htmlifying $$h\n);" \\
-e "  $$dir = dirname($$h); mkpath($$dir) unless -d $$dir;" \\
-e "  system(q[$(PERLRUN) $(POD2HTML_EXE) ].qq[$$p > $$h])==0 " \\
-e "    or warn qq(Couldn\\047t install $$h\n);" \\
-e "  chmod(oct($(PERM_RW))), $$h " \\
-e "    or warn qq(chmod $(PERM_RW) $$h: $$!\n);" \\
-e "}"

MAKE_TEXT

    $m .= "htmlifypods : pure_all ";
    $m .= join " \\\n\t", keys %{$self->{HTMLLIBPODS}},
                          keys %{$self->{HTMLSCRIPTPODS}};

    $m .= "\n";
    if (keys %{$self->{HTMLLIBPODS}} || keys %{$self->{HTMLSCRIPTPODS}}) {
        $m .= "\t$self->{NOECHO}\$(POD2HTML) \\\n\t";
        $m .= join " \\\n\t", %{$self->{HTMLLIBPODS}}, 
                              %{$self->{HTMLSCRIPTPODS}};
    }

    return $m;
}

=item test_via_harness

  my $command = $mm->test_via_harness($perl, $tests);

Returns a $command line which runs the given set of $tests with
Test::Harness and the given $perl.

Used on the t/*.t files.

=cut

sub test_via_harness {
    my($self, $perl, $tests) = @_;

    return "\t$perl".q{ $(TEST_LIBS) "-e" 'use Test::Harness;  $$Test::Harness::Verbose=$(TEST_VERBOSE); runtests @ARGV;' } . "$tests\n";
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
    return "\t$perl \$(TEST_LIBS) $script\n";
}

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with code from ExtUtils::MM_Unix
and ExtUtils::MM_Win32.


=cut

1;
