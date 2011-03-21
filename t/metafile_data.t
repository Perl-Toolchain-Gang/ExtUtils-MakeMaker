BEGIN {
    unshift @INC, 't/lib';
}

use strict;
use Test::More tests => 10;

use Data::Dumper;

require ExtUtils::MM_Any;

my $new_mm = sub {
    return bless { ARGS => {@_}, @_ }, 'ExtUtils::MM_Any';
};

{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        PM              => {
            "Foo::Bar"          => 'lib/Foo/Bar.pm',
        },
    );

    is_deeply {$mm->metafile_data}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },
        build_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },

        no_index        => {
            directory           => [qw(t inc)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    };


    is_deeply {$mm->metafile_data({}, { no_index => { directory => [qw(foo)] } })}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },
        build_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },

        no_index        => {
            directory           => [qw(t inc foo)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    }, 'rt.cpan.org 39348';
}


{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        AUTHOR          => ['Some Guy'],
        PREREQ_PM       => {
            Foo                 => 2.34,
            Bar                 => 4.56,
        },
    );

    is_deeply {$mm->metafile_data(
        {
            configure_requires => {
                Stuff   => 2.34
            },
            wobble      => 42
        },
        {
            no_index    => {
                package => "Thing"
            },
            wibble      => 23
        },
    )},
    {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => ['Some Guy'],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'script',

        configure_requires      => {
            Stuff       => 2.34,
        },
        build_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },

        requires       => {
            Foo                 => 2.34,
            Bar                 => 4.56,
        },

        no_index        => {
            directory           => [qw(t inc)],
            package             => 'Thing',
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },

        wibble  => 23,
        wobble  => 42,
    };
}


# Test MIN_PERL_VERSION
{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        PM              => {
            "Foo::Bar"          => 'lib/Foo/Bar.pm',
        },
        MIN_PERL_VERSION => 5.006,
    );

    is_deeply {$mm->metafile_data}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },
        build_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },

        requires        => {
            perl        => '5.006',
        },

        no_index        => {
            directory           => [qw(t inc)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    };
}


# Test MIN_PERL_VERSION
{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        PM              => {
            "Foo::Bar"          => 'lib/Foo/Bar.pm',
        },
        MIN_PERL_VERSION => 5.006,
        PREREQ_PM => {
            'Foo::Bar'  => 1.23,
        },
    );

    is_deeply {$mm->metafile_data}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },
        build_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },

        requires        => {
            perl        => '5.006',
            'Foo::Bar'  => 1.23,
        },

        no_index        => {
            directory           => [qw(t inc)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    };
}

# Test CONFIGURE_REQUIRES
{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        CONFIGURE_REQUIRES => {
            "Fake::Module1" => 1.01,
        },
        PM              => {
            "Foo::Bar"          => 'lib/Foo/Bar.pm',
        },
    );

    is_deeply {$mm->metafile_data}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'Fake::Module1'       => 1.01,
        },
        build_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },

        no_index        => {
            directory           => [qw(t inc)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    },'CONFIGURE_REQUIRES';
}

# Test BUILD_REQUIRES
{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        BUILD_REQUIRES => {
            "Fake::Module1" => 1.01,
        },
        PM              => {
            "Foo::Bar"          => 'lib/Foo/Bar.pm',
        },
    );

    is_deeply {$mm->metafile_data}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },
        build_requires      => {
            'Fake::Module1'       => 1.01,
        },

        no_index        => {
            directory           => [qw(t inc)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    },'CONFIGURE_REQUIRES';
}

# Test _REQUIRES key priority over META_ADD

{
    my $mm = $new_mm->(
        DISTNAME        => 'Foo-Bar',
        VERSION         => 1.23,
        BUILD_REQUIRES => {
            "Fake::Module1" => 1.01,
        },
        META_ADD => (my $meta_add = { build_requires => {} }),
        PM              => {
            "Foo::Bar"          => 'lib/Foo/Bar.pm',
        },
    );

    is_deeply {$mm->metafile_data($meta_add)}, {
        name            => 'Foo-Bar',
        version         => 1.23,
        abstract        => 'unknown',
        author          => [],
        license         => 'unknown',
        dynamic_config  => 1,
        distribution_type       => 'module',

        configure_requires      => {
            'ExtUtils::MakeMaker'       => 0,
        },
        build_requires      => { },

        no_index        => {
            directory           => [qw(t inc)],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    },'META.yml data (META_ADD wins)';


    require CPAN::Meta;
    my $want_mymeta = {
        name            => 'ExtUtils-MakeMaker',
        version         => '6.57_07',
        abstract        => 'Create a module Makefile',
        author          => ['Michael G Schwern <schwern@pobox.com>'],
        license         => 'perl',
        dynamic_config  => 0,

        requires        => {
            "DirHandle"         => 0,
            "File::Basename"    => 0,
            "File::Spec"        => "0.8",
            "Pod::Man"          => 0,
            "perl"              => "5.006"
        },

        configure_requires      => {
        },
        build_requires      => {
            'Fake::Module1'       => 1.01,
        },

        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            homepage    =>      'http://makemaker.org',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=ExtUtils-MakeMaker',
            repository  =>      'http://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker',
            x_MailingList =>      'makemaker@perl.org',
        },

        no_index        => {
            directory           => [qw(t inc)],
            package             => ["DynaLoader", "in"],
        },

        generated_by => "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION, CPAN::Meta::Converter version $CPAN::Meta::VERSION",
        'meta-spec'  => {
            url         => 'http://module-build.sourceforge.net/META-spec-v1.4.html', 
            version     => 1.4
        },
    };

    is_deeply $mm->mymeta("t/META_for_testing.json"),
              $want_mymeta,
              'MYMETA JSON data (BUILD_REQUIRES wins)';

    is_deeply $mm->mymeta("t/META_for_testing.yml"),
              $want_mymeta,
              'MYMETA YAML data (BUILD_REQUIRES wins)';
}
