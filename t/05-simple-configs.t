use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use File::pushd 'pushd';

use Dist::Zilla::Plugin::MakeMaker::Awesome;
{
    package Dist::Zilla::Plugin::MakeMaker::Awesome;
    use Moose;
    __PACKAGE__->meta->make_mutable;
    before _build_test_files => sub {
        ::fail '_build_test_files was called';
    };
    before _build_exe_files => sub {
        ::fail '_build_exe_files was called';
    };
}

my $tzil = Builder->from_config(
    { dist_root => 'does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
            ) . <<END_INI,

[MakeMaker::Awesome]
WriteMakefile_arg = CCFLAGS => 'Wall'
test_file = xt/*.t
exe_file = bin/hello-world
END_INI
            path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
            path(qw(source xt foo.t)) => 'warn "here is an extra test";',
            path(qw(source bin hello-world)) => "#!/usr/bin/perl\nprint \"hello!\\n\"",
        },
    },
);

$tzil->build;

my $content = $tzil->slurp_file('build/Makefile.PL');

like(
    $content,
    qr{^\s+"TESTS"\s+=>\s+\Q"xt/*.t"\E}ms,
    'test_files were set',
);
like(
    $content,
    qr{^\s+"EXE_FILES"\s+=>\s+\[\n^\s+"bin/hello-world"\n^\s+\],}ms,
    'exe files were set',
);
like(
    $content,
    qr/^%WriteMakefileArgs = \(\n^    %WriteMakefileArgs,\n^    CCFLAGS => 'Wall',\n^\);\n/ms,
    'additional WriteMakefile argument is set',
);

subtest 'run the generated Makefile.PL' => sub
{
    my $wd = pushd path($tzil->tempdir)->child('build');
    is(
        exception { $tzil->plugin_named('MakeMaker::Awesome')->build },
        undef,
        'Makefile.PL can be run successfully',
    );
};

done_testing;
