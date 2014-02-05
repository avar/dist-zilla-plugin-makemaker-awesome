# NAME

Dist::Zilla::Plugin::MakeMaker::Awesome - A more awesome MakeMaker plugin for [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)

# VERSION

version 0.20

# SYNOPSIS

In your `dist.ini`:

    ;; Replace [MakeMaker]
    ;[MakeMaker]
    [=inc::MyMakeMaker]

# DESCRIPTION

[Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)'s [MakeMaker](https://metacpan.org/pod/Dist::Zilla::Plugin::MakeMaker) plugin is
limited, if you want to stray from the marked path and do something
that would normally be done in a `package MY` section or otherwise
run custom code in your `Makefile.PL` you're out of luck.

This plugin is 100% compatible with [Dist::Zilla::Plugin::MakeMaker](https://metacpan.org/pod/Dist::Zilla::Plugin::MakeMaker),
so if you need something more complex you can just subclass it.

As an example, adding a `package MY` section to your
`Makefile.PL`:

In your `dist.ini`:

    [=inc::MyDistMakeMaker / MyDistMakeMaker]

Then in your `inc/MyDistMakeMaker.pm`, real example from [Hailo](https://metacpan.org/pod/Hailo)
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
in [re::engine::PCRE](https://metacpan.org/pod/re::engine::PCRE):

    package inc::PCREMakeMaker;
    use Moose;

    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    override _build_WriteMakefile_args => sub { +{
        # Add LIBS => to WriteMakefile() args
        %{ super() },
        LIBS => [ '-lpcre' ],
    } };

    __PACKAGE__->meta->make_immutable;

And another example from [re::engine::Plan9](https://metacpan.org/pod/re::engine::Plan9):

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

If you have custom code in your [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)-based
[Makefile.PL](https://metacpan.org/pod/Makefile.PL) that [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) can't replace via its default
facilities you'll be able replace it by using this module.

Even if your `Makefile.PL` isn't [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)-based you
should be able to override it. You'll just have to provide a new
["\_build\_MakeFile\_PL\_template"](#_build_makefile_pl_template).

# OVERRIDE

These are the methods you can currently `override` or method-modify in your
custom `inc/` module. The work that this module does is entirely done in
small modular methods that can be overridden in your subclass. Here are
some of the highlights:

## \_build\_MakeFile\_PL\_template

Returns a [Text::Template](https://metacpan.org/pod/Text::Template) string used to construct the `Makefile.PL`.

If you need to insert some additional code to the beginning or end of
`Makefile.PL` (without modifying the existing content, you should use an
`around` method modifier, something like this:

    around _build_MakeFile_PL_template => sub {
        my $orig = shift;
        my $self = shift;

        my $NEW_CONTENT = ...;

        # insert new content near the beginning of the file, preserving the
        # preamble header
        my $string = $self->$orig(@_);
        $string =~ m/use warnings;\n\n/g;
        return substr($string, 0, pos($string)) . $NEW_CONTENT . substr($string, pos($string));
    };

## \_build\_WriteMakefile\_args

A `HashRef` of arguments that will be passed to
[ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)'s `WriteMakefile` function.

## \_build\_WriteMakefile\_dump

Takes the return value of ["\_build\_WriteMakefile\_args"](#_build_writemakefile_args) and
constructs a [Str](https://metacpan.org/pod/Str) that will be included in the `Makefile.PL` by
["\_build\_MakeFile\_PL\_template"](#_build_makefile_pl_template).

## test\_dirs

## exe\_files

## register\_prereqs

## setup\_installer

The test/bin/share dirs and exe\_files. These will all be passed to
`/"_build_WriteMakefile_args"` later.

## \_build\_share\_dir\_block

An `ArrayRef[Str]` with two elements to be used by
["\_build\_MakeFile\_PL\_template"](#_build_makefile_pl_template). The first will declare your
[sharedir](https://metacpan.org/pod/File::ShareDir::Install) and the second will add a magic
`package MY` section to install it. Deep magic.

## OTHER

The main entry point is `setup_installer` via the
[Dist::Zilla::Role::InstallTool](https://metacpan.org/pod/Dist::Zilla::Role::InstallTool) role. There are also other magic
Dist::Zilla roles, check the source for more info.

# DIAGNOSTICS

- attempt to add Makefile.PL multiple times

    This error from [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) means that you've used both
    `[MakeMaker]` and `[MakeMaker::Awesome]`. You've either included
    `MakeMaker` directly in `dist.ini`, or you have plugin bundle that
    includes it. See [@Filter](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Filter) for how
    to filter it out.

# BUGS

This plugin would suck less if [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) didn't use a INI-based
config system so you could add a stuff like this in your main
configuration file like you can with [Module::Install](https://metacpan.org/pod/Module::Install).

The `.ini` file format can only support key-value pairs whereas any
complex use of [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) requires running custom Perl
code and passing complex data structures to `WriteMakefile`.

# AUTHOR

Ævar Arnfjörð Bjarmason <avar@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ævar Arnfjörð Bjarmason.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# CONTRIBUTORS

- Jesse Luehrs <doy@tozt.net>
- Karen Etheridge <ether@cpan.org>
- Robin Smidsrød <robin@smidsrod.no>
