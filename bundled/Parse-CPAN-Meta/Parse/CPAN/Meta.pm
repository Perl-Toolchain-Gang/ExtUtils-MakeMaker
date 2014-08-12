use strict;
package Parse::CPAN::Meta;
# ABSTRACT: Parse META.yml and META.json CPAN metadata files
our $VERSION = '1.4405'; # VERSION

use Carp 'croak';

# UTF Support?
sub HAVE_UTF8 () { $] >= 5.007003 }
sub IO_LAYER () { $] >= 5.008001 ? ":utf8" : "" }  

BEGIN {
	if ( HAVE_UTF8 ) {
		# The string eval helps hide this from Test::MinimumVersion
		eval "require utf8;";
		die "Failed to load UTF-8 support" if $@;
	}

	# Class structure
	require 5.004;
	require Exporter;
	@Parse::CPAN::Meta::ISA       = qw{ Exporter      };
	@Parse::CPAN::Meta::EXPORT_OK = qw{ Load LoadFile };
}

sub load_file {
  my ($class, $filename) = @_;

  if ($filename =~ /\.ya?ml$/) {
    return $class->load_yaml_string(_slurp($filename));
  }

  if ($filename =~ /\.json$/) {
    return $class->load_json_string(_slurp($filename));
  }

  croak("file type cannot be determined by filename");
}

sub load_yaml_string {
  my ($class, $string) = @_;
  my $backend = $class->yaml_backend();
  my $data = eval { no strict 'refs'; &{"$backend\::Load"}($string) };
  if ( $@ ) { 
    croak $backend->can('errstr') ? $backend->errstr : $@
  }
  return $data || {}; # in case document was valid but empty
}

sub load_json_string {
  my ($class, $string) = @_;
  return $class->json_backend()->new->decode($string);
}

sub yaml_backend {
  local $Module::Load::Conditional::CHECK_INC_HASH = 1;
  if (! defined $ENV{PERL_YAML_BACKEND} ) {
    _can_load( 'CPAN::Meta::YAML', 0.002 )
      or croak "CPAN::Meta::YAML 0.002 is not available\n";
    return "CPAN::Meta::YAML";
  }
  else {
    my $backend = $ENV{PERL_YAML_BACKEND};
    _can_load( $backend )
      or croak "Could not load PERL_YAML_BACKEND '$backend'\n";
    $backend->can("Load")
      or croak "PERL_YAML_BACKEND '$backend' does not implement Load()\n";
    return $backend;
  }
}

sub json_backend {
  local $Module::Load::Conditional::CHECK_INC_HASH = 1;
  if (! $ENV{PERL_JSON_BACKEND} or $ENV{PERL_JSON_BACKEND} eq 'JSON::PP') {
    _can_load( 'JSON::PP' => 2.27103 )
      or croak "JSON::PP 2.27103 is not available\n";
    return 'JSON::PP';
  }
  else {
    _can_load( 'JSON' => 2.5 )
      or croak  "JSON 2.5 is required for " .
                "\$ENV{PERL_JSON_BACKEND} = '$ENV{PERL_JSON_BACKEND}'\n";
    return "JSON";
  }
}

sub _slurp {
  open my $fh, "<" . IO_LAYER, "$_[0]"
    or die "can't open $_[0] for reading: $!";
  return do { local $/; <$fh> };
}
  
sub _can_load {
  my ($module, $version) = @_;
  (my $file = $module) =~ s{::}{/}g;
  $file .= ".pm";
  return 1 if $INC{$file};
  return 0 if exists $INC{$file}; # prior load failed
  eval { require $file; 1 }
    or return 0;
  if ( defined $version ) {
    eval { $module->VERSION($version); 1 }
      or return 0;
  }
  return 1;
}

# Kept for backwards compatibility only
# Create an object from a file
sub LoadFile ($) {
  require CPAN::Meta::YAML;
  my $object = CPAN::Meta::YAML::LoadFile(shift)
    or die CPAN::Meta::YAML->errstr;
  return $object;
}

# Parse a document from a string.
sub Load ($) {
  require CPAN::Meta::YAML;
  my $object = CPAN::Meta::YAML::Load(shift)
    or die CPAN::Meta::YAML->errstr;
  return $object;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Parse::CPAN::Meta - Parse META.yml and META.json CPAN metadata files

=head1 VERSION

version 1.4405

=head1 SYNOPSIS

    #############################################
    # In your file
    
    ---
    name: My-Distribution
    version: 1.23
    resources:
      homepage: "http://example.com/dist/My-Distribution"
    
    
    #############################################
    # In your program
    
    use Parse::CPAN::Meta;
    
    my $distmeta = Parse::CPAN::Meta->load_file('META.yml');
    
    # Reading properties
    my $name     = $distmeta->{name};
    my $version  = $distmeta->{version};
    my $homepage = $distmeta->{resources}{homepage};

=head1 DESCRIPTION

B<Parse::CPAN::Meta> is a parser for F<META.json> and F<META.yml> files, using
L<JSON::PP> and/or L<CPAN::Meta::YAML>.

B<Parse::CPAN::Meta> provides three methods: C<load_file>, C<load_json_string>,
and C<load_yaml_string>.  These will read and deserialize CPAN metafiles, and
are described below in detail.

B<Parse::CPAN::Meta> provides a legacy API of only two functions,
based on the YAML functions of the same name. Wherever possible,
identical calling semantics are used.  These may only be used with YAML sources.

All error reporting is done with exceptions (die'ing).

Note that META files are expected to be in UTF-8 encoding, only.  When
converted string data, it must first be decoded from UTF-8.

=for Pod::Coverage HAVE_UTF8 IO_LAYER

=head1 METHODS

=head2 load_file

  my $metadata_structure = Parse::CPAN::Meta->load_file('META.json');

  my $metadata_structure = Parse::CPAN::Meta->load_file('META.yml');

This method will read the named file and deserialize it to a data structure,
determining whether it should be JSON or YAML based on the filename.  On
Perl 5.8.1 or later, the file will be read using the ":utf8" IO layer.

=head2 load_yaml_string

  my $metadata_structure = Parse::CPAN::Meta->load_yaml_string($yaml_string);

This method deserializes the given string of YAML and returns the first
document in it.  (CPAN metadata files should always have only one document.)
If the source was UTF-8 encoded, the string must be decoded before calling
C<load_yaml_string>.

=head2 load_json_string

  my $metadata_structure = Parse::CPAN::Meta->load_json_string($json_string);

This method deserializes the given string of JSON and the result.  
If the source was UTF-8 encoded, the string must be decoded before calling
C<load_json_string>.

=head2 yaml_backend

  my $backend = Parse::CPAN::Meta->yaml_backend;

Returns the module name of the YAML serializer. See L</ENVIRONMENT>
for details.

=head2 json_backend

  my $backend = Parse::CPAN::Meta->json_backend;

Returns the module name of the JSON serializer.  This will either
be L<JSON::PP> or L<JSON>.  Even if C<PERL_JSON_BACKEND> is set,
this will return L<JSON> as further delegation is handled by
the L<JSON> module.  See L</ENVIRONMENT> for details.

=head1 FUNCTIONS

For maintenance clarity, no functions are exported.  These functions are
available for backwards compatibility only and are best avoided in favor of
C<load_file>.

=head2 Load

  my @yaml = Parse::CPAN::Meta::Load( $string );

Parses a string containing a valid YAML stream into a list of Perl data
structures.

=head2 LoadFile

  my @yaml = Parse::CPAN::Meta::LoadFile( 'META.yml' );

Reads the YAML stream from a file instead of a string.

=head1 ENVIRONMENT

=head2 PERL_JSON_BACKEND

By default, L<JSON::PP> will be used for deserializing JSON data. If the
C<PERL_JSON_BACKEND> environment variable exists, is true and is not
"JSON::PP", then the L<JSON> module (version 2.5 or greater) will be loaded and
used to interpret C<PERL_JSON_BACKEND>.  If L<JSON> is not installed or is too
old, an exception will be thrown.

=head2 PERL_YAML_BACKEND

By default, L<CPAN::Meta::YAML> will be used for deserializing YAML data. If
the C<PERL_YAML_BACKEND> environment variable is defined, then it is interpreted
as a module to use for deserialization.  The given module must be installed,
must load correctly and must implement the C<Load()> function or an exception
will be thrown.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-CPAN-Meta>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<http://github.com/Perl-Toolchain-Gang/Parse-CPAN-Meta>

  git clone git://github.com/Perl-Toolchain-Gang/Parse-CPAN-Meta.git

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Joshua ben Jore <jjore@cpan.org>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Steffen M�ller <smueller@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Adam Kennedy and Contributors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
