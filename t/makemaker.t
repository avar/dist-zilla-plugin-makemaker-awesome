use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use Test::DZil;
use Path::Tiny;

{
  my $tzil = Builder->from_config(
    { dist_root => 'does_not_exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          'GatherDir',
          'MakeMaker::Awesome',
          [ Prereqs => { 'Foo::Bar' => '1.20',      perl => '5.008' } ],
          [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereqs => TestRequires  => { 'Test::Deet'   => '7',
                                          perl           => '5.008' } ],
        ),
        path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
        path(qw(source t basic.t)) => 'warn "here is a test";',
      },
    },
  );

  $tzil->build;

  my $makemaker = $tzil->plugin_named('MakeMaker::Awesome');

  my %want = (
    DISTNAME => 'DZT-Sample',
    NAME     => 'DZT::Sample',
    ABSTRACT => 'Sample DZ Dist',
    VERSION  => '0.001',
    AUTHOR   => 'E. Xavier Ample <example@example.org>',
    LICENSE  => 'perl',

    PREREQ_PM          => {
      'Foo::Bar' => '1.20'
    },
    BUILD_REQUIRES     => {
      'Builder::Bob' => '9.901',
    },
    TEST_REQUIRES      => {
      'Test::Deet'   => '7',
    },
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.30'
    },
    EXE_FILES => [],
    test => { TESTS => 't/*.t' },
  );

  cmp_deeply(
    { $makemaker->WriteMakefile_args },
    \%want,
    'correct makemaker args generated',
  );

  my $content = $tzil->slurp_file('build/Makefile.PL');
  like(
    $content,
    qr/(?{ quotemeta($tzil->plugin_named('MakeMaker::Awesome')->_dump_as(\%want, '*WriteMakefileArgs')) })/,
    'arguments are dumped to Makefile.PL',
  );
}

{
  my $tzil = Builder->from_config(
    { dist_root => 'does_not_exist' },
    {
      add_files => {
        path(qw(source dist.ini)) => simple_ini(
          'GatherDir',
          [ 'MakeMaker::Awesome' => { makefile_args_hook => "\$WriteMakefileArgs{LIBS} = ['-lsome'];\n" } ],
          [ Prereqs => { 'Foo::Bar' => '1.20',      perl => '5.008' } ],
          [ Prereqs => BuildRequires => { 'Builder::Bob' => '9.901' } ],
          [ Prereqs => TestRequires  => { 'Test::Deet'   => '7',
                                          perl           => '5.008' } ],
        ),
        path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
        path(qw(source t basic.t)) => 'warn "here is a test";',
      },
    },
  );

  $tzil->build;

  my $content = $tzil->slurp_file('build/Makefile.PL');
  like(
    $content,
    qr/^my\s+\%WriteMakefileArgs\s*=\s*\(.+^\$WriteMakefileArgs\{LIBS\} = \['-lsome'\];.+^WriteMakefile\(/ms,
    'our hook exists in its place Makefile.PL',
  );
}

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
