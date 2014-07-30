use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny;
use Test::Deep;
use Test::Deep::JSON;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 't/does_not_exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                'MakeMaker::Awesome',
                'MetaJSON',
                'MetaConfig',
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n\n1",
        },
    },
);

$tzil->build;
my $json = path($tzil->tempdir, qw(build META.json))->slurp_raw;

cmp_deeply(
    $json,
    json(superhashof({
        dynamic_config => 0,
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                superhashof({
                    class => 'Dist::Zilla::Plugin::MakeMaker::Awesome',
                    config => superhashof({
                        # [MakeMaker] might also record some configs of its own
                        'Dist::Zilla::Role::TestRunner' => ignore,  # changes over time
                    }),
                    name => 'MakeMaker::Awesome',
                    version => ignore,
                })
            ),
        })
    })),
    'config is properly included in metadata',
);

done_testing;
