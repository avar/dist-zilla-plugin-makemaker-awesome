use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                'MakeMaker::Awesome',
                [ Prereqs => { 'External::Module' => '<= 1.23' } ],
            ),
            'source/lib/Foo.pm' => "package Foo;\n1\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

cmp_deeply(
    $tzil->log_messages,
    superbagof('[MakeMaker::Awesome] found version range in runtime prerequisites, which ExtUtils::MakeMaker cannot parse: External::Module <= 1.23'),
    'got warning about probably-unparsable version range',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
