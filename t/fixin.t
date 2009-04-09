#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib/');
    }
    else {
        unshift @INC, 't/lib/';
    }
}
chdir 't';

use File::Spec;

use Test::More tests => 11;

use Config;
use TieOut;
use MakeMaker::Test::Utils;
use MakeMaker::Test::Setup::BFD;

use ExtUtils::MakeMaker;

chdir 't';

perl_lib();

ok( setup_recurs(), 'setup' );
END {
    ok( chdir File::Spec->updir );
    ok( teardown_recurs(), 'teardown' );
}

ok( chdir 'Big-Dummy', "chdir'd to Big-Dummy" ) ||
  diag("chdir failed: $!");

# [rt.cpan.org 26234]
{
    local $/ = "foo";
    local $\ = "bar";
    MY->fixin("bin/program");
    is $/, "foo", '$/ not clobbered';
    is $\, "bar", '$\ not clobbered';
}


# [rt.cpan.org 29442]
{
    my $file = "fixin.test";
    ok open my $fh, ">", $file;
    print $fh <<END;
#!/foo/bar/perl -w

blah blah blah
END

    close $fh;

    MY->fixin($file);

    ok open $fh, "<", $file;
    my @lines = <$fh>;
    close $fh;

    is $lines[0], "$Config{startperl} -w\n", "#! replaced";

    # In between might be that "not running under some shell" madness.

    is $lines[-1], "blah blah blah\n", "Program text retained";

    ok unlink $file;
}
