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

use Test::More tests => 20;

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


sub test_fixin {
    my($code, $test) = @_;

    my $file = "fixin.test";
    ok open my $fh, ">", $file;
    print $fh $code;
    close $fh;

    MY->fixin($file);

    ok open $fh, "<", $file;
    my @lines = <$fh>;
    close $fh;

    $test->(@lines);

    ok unlink $file;
}


# A simple test of fixin
test_fixin(<<END,
#!/foo/bar/perl -w

blah blah blah
END
    sub {
        my @lines = @_;
        is $lines[0], "$Config{startperl} -w\n", "#! replaced";
        
        # In between might be that "not running under some shell" madness.
               
        is $lines[-1], "blah blah blah\n", "Program text retained";
    }
);


# [rt.cpan.org 29442]
test_fixin(<<END,
#!/foo/bar/perl5.8.8 -w

blah blah blah
END

    sub {
        my @lines = @_;

        is $lines[0], "$Config{startperl} -w\n", "#! replaced";

        # In between might be that "not running under some shell" madness.

        is $lines[-1], "blah blah blah\n", "Program text retained";
    }
);


# fixin shouldn't pick this up.
test_fixin(<<END,
#!/foo/bar/perly -w

blah blah blah
END

    sub {
        is join("", @_), <<END;
#!/foo/bar/perly -w

blah blah blah
END
    }
);
