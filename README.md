# NAME

Dist::Zilla::Plugin::MakeMaker::Awesome - A more awesome MakeMaker plugin for [Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla)

# VERSION

version 0.16

# SYNOPSIS

In your `dist.ini`:

    ;; Replace [MakeMaker]
    ;[MakeMaker]
    [=inc::MyMakeMaker]

# DESCRIPTION

[Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla)'s [MakeMaker](http://search.cpan.org/perldoc?Dist::Zilla::Plugin::MakeMaker) plugin is
limited, if you want to stray from the marked path and do something
that would normally be done in a `package MY` section or otherwise
run custom code in your `Makefile.PL` you're out of luck.

This plugin is 100% compatible with [Dist::Zilla::Plugin::MakeMaker](http://search.cpan.org/perldoc?Dist::Zilla::Plugin::MakeMaker),
so if you need something more complex you can just subclass it.

As an example, adding a `package MY` section to your
`Makefile.PL`:

In your `dist.ini`:

    [=inc::MyDistMakeMaker / MyDistMakeMaker]

Then in your `inc/MyDistMakeMaker.pm`, real example from [Hailo](http://search.cpan.org/perldoc?Hailo)
(which has `[=inc::HailoMakeMaker / HailoMakeMaker]` in its
`dist.ini`):

    package inc::HailoMakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_MakeFile_PL_template => sub {
        my ($self) = @_;
        my $template = super();

        $template .= <<'TEMPLATE';
    package MY;

    sub test {
        my $inherited = shift->SUPER::test(@_);

        # Run tests with Moose and Mouse
        $inherited =~ s/^test_dynamic :: pure_all\n\t(.*?)\n/test_dynamic :: pure_all\n\tANY_MOOSE=Mouse $1\n\tANY_MOOSE=Moose $1\n/m;

        return $inherited;
    }
    TEMPLATE

        return $template;
    };

    __PACKAGE__->meta->make_immutable;

Or maybe you're writing an XS distro and want to pass custom arguments
to `WriteMakefile()`, here's an example of adding a `LIBS` argument
in [re::engine::PCRE](http://search.cpan.org/perldoc?re::engine::PCRE):

    package inc::PCREMakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_WriteMakefile_args => sub { +{
        # Add LIBS => to WriteMakefile() args
        %{ super() },
        LIBS => [ '-lpcre' ],
    } };

    __PACKAGE__->meta->make_immutable;

And another example from [re::engine::Plan9](http://search.cpan.org/perldoc?re::engine::Plan9):

    package inc::Plan9MakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_WriteMakefile_args => sub {
        my ($self) = @_;

        our @DIR = qw(libutf libfmt libregexp);
        our @OBJ = map { s/\.c$/.o/; $_ }
                   grep { ! /test/ }
                   glob "lib*/*.c";

        return +{
            %{ super() },
            DIR           => [ @DIR ],
            INC           => join(' ', map { "-I$_" } @DIR),

            # This used to be '-shared lib*/*.o' but that doesn't work on Win32
            LDDLFLAGS     => "-shared @OBJ",
        };
    };

    __PACKAGE__->meta->make_immutable;

If you have custom code in your [ExtUtils::MakeMaker](http://search.cpan.org/perldoc?ExtUtils::MakeMaker)\-based
[Makefile.PL](http://search.cpan.org/perldoc?Makefile.PL) that [Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla) can't replace via its default
facilities you'll be able replace it by using this module.

Even if your `Makefile.PL` isn't [ExtUtils::MakeMaker](http://search.cpan.org/perldoc?ExtUtils::MakeMaker)\-based you
should be able to override it. You'll just have to provide a new
["\_build\_MakeFile\_PL\_template"](#\_build\_MakeFile\_PL\_template).

# OVERRIDE

These are the methods you can currently `override` or method-modify in your
custom `inc/` module. The work that this module does is entirely done in
small modular methods that can be overridden in your subclass. Here are
some of the highlights:

## \_build\_MakeFile\_PL\_template

Returns a [Text::Template](http://search.cpan.org/perldoc?Text::Template) string used to construct the `Makefile.PL`.

## \_build\_WriteMakefile\_args

A `HashRef` of arguments that will be passed to
[ExtUtils::MakeMaker](http://search.cpan.org/perldoc?ExtUtils::MakeMaker)'s `WriteMakefile` function.

## \_build\_WriteMakefile\_dump

Takes the return value of ["\_build\_WriteMakefile\_args"](#\_build\_WriteMakefile\_args) and
constructs a [Str](http://search.cpan.org/perldoc?Str) that will be included in the `Makefile.PL` by
["\_build\_MakeFile\_PL\_template"](#\_build\_MakeFile\_PL\_template).

## test\_dirs

## exe\_files

## register\_prereqs

## setup\_installer

The test/bin/share dirs and exe\_files. These will all be passed to
`/"\_build\_WriteMakefile\_args"` later.

## \_build\_share\_dir\_block

An `ArrayRef[Str]` with two elements to be used by
["\_build\_MakeFile\_PL\_template"](#\_build\_MakeFile\_PL\_template). The first will declare your
[sharedir](http://search.cpan.org/perldoc?File::ShareDir::Install) and the second will add a magic
`package MY` section to install it. Deep magic.

## OTHER

The main entry point is `setup_installer` via the
[Dist::Zilla::Role::InstallTool](http://search.cpan.org/perldoc?Dist::Zilla::Role::InstallTool) role. There are also other magic
Dist::Zilla roles, check the source for more info.

# DIAGNOSTICS

- attempt to add Makefile.PL multiple times

    This error from [Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla) means that you've used both
    `[MakeMaker]` and `[MakeMaker::Awesome]`. You've either included
    `MakeMaker` directly in `dist.ini`, or you have plugin bundle that
    includes it. See [@Filter](http://search.cpan.org/perldoc?Dist::Zilla::PluginBundle::Filter) for how
    to filter it out.

# BUGS

This plugin would suck less if [Dist::Zilla](http://search.cpan.org/perldoc?Dist::Zilla) didn't use a INI-based
config system so you could add a stuff like this in your main
configuration file like you can with [Module::Install](http://search.cpan.org/perldoc?Module::Install).

The `.ini` file format can only support key-value pairs whereas any
complex use of [ExtUtils::MakeMaker](http://search.cpan.org/perldoc?ExtUtils::MakeMaker) requires running custom Perl
code and passing complex data structures to `WriteMakefile`.

# AUTHOR

Ã†var ArnfjÃ¶rÃ° Bjarmason <avar@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ã†var ArnfjÃ¶rÃ° Bjarmason.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# CONTRIBUTORS

- Jesse Luehrs <doy@tozt.net>
- Karen Etheridge <ether@cpan.org>
- Robin Smidsrød <robin@smidsrod.no>
- Ævar Arnfjörð Bjarmason <avar@cpan.org>
