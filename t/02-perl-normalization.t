use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          'GatherDir',
          'MakeMaker',
          [ Prereqs => { perl => '5.8.1' } ],
        ),
      },
    },
  );

  $tzil->build;

  my $content = $tzil->slurp_file('build/Makefile.PL');

  like($content, qr/^use 5\.008001;\s*$/m, "normalized the perl version needed");
}

done_testing;
