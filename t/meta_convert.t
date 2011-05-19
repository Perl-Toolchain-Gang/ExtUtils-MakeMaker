BEGIN {
    chdir '..' if -d '../t';
    unshift @INC, 't/lib';
    use lib 'lib';
}

use strict;
use warnings;
use Test::More 'no_plan';

require ExtUtils::MM_Any;

sub ExtUtils::MM_Any::quote_literal { $_[1] }

my $new_mm = sub {
    return bless { ARGS => {@_}, @_ }, 'ExtUtils::MM_Any';
};

my $version_regex = qr/version: ''/;
my $version_action = "they're converted to empty string";

{
    my $mm = $new_mm->(
        DISTNAME => 'Net::FTP::Recursive',
        VERSION  => 'Recursive.pm',
    );
    my $res = eval { $mm->metafile_target };
    ok $res, 'we know how to deal with bogus versions defined in Makefile.PL';
    like $res, $version_regex, $version_action;
}
{
    my $mm = $new_mm->(
        DISTNAME => 'Image::Imgur',
        VERSION  => 'undef',
    );
    my $res = eval { $mm->metafile_target };
    ok $res, q|when there's no $VERSION in Module.pm, $self->{VERSION} = 'undef'; via MM_Unix::parse_version and we know how to deal with that|;
    like $res, $version_regex, $version_action;
}
{
    my $mm = $new_mm->(
        DISTNAME => 'SQL::Library',
        VERSION  => 0.0.3,
    );
    my $res = eval { $mm->metafile_target };
    ok $res, q|we know how to deal with our $VERSION = 0.0.3; style versions defined in the module|;
    like $res, $version_regex, $version_action;
}
{
    my $mm = $new_mm->(
        DISTNAME => 'Array::Suffix',
        VERSION  => '.5',
    );
    my $res = eval { $mm->metafile_target };
    ok $res, q|we know how to deal with our $VERSION = '.5'; style versions defined in the module|;
    like $res, $version_regex, $version_action;
}
{
    my $mm = $new_mm->(
        DISTNAME   => 'Attribute::Signature',
        META_MERGE => {
            resources => {
                repository         => 'http://github.com/chorny/Attribute-Signature',
                'Repository-clone' => 'git://github.com/chorny/Attribute-Signature.git',
            },
        },
    );
    my $res = eval { $mm->metafile_target };
    ok $res, q|we know how to deal with non-camel-cased custom meta resource keys defined in Makefile.PL|;
    like $res, qr/x_Repositoryclone:/, "they're camel-cased";
}
