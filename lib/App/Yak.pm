package App::Yak;

## no critic (RequireExtendedFormatting ProhibitVersionStrings RequireArgUnpacking ProhibitPackageVars)

use strict;
use warnings;
use v5.10;  # say
            # stacked file tests, REF: https://perldoc.perl.org/functions/-X
use utf8;
use YAML::Tiny;
use JSON; # from_json
use Term::ANSIColor qw(); # color is exported by default unless we supress it
use Crypt::Digest::SHA256 qw(sha256_file_hex sha256_hex); # Provided by CryptX
use List::MoreUtils qw(any);
use Data::Stack;
use Text::Gitignore qw(match_gitignore build_gitignore_matcher);
use Cwd; # getcwd
use File::Find; # find
use File::Slurper qw(read_lines read_text);
use Readonly;
use Carp; # croak
use Clone 'clone';
use LWP::UserAgent;
use Try::Tiny;

use Env qw($HOME $YAK_SUCCESS_COLOR $YAK_FAILURE_COLOR $YAK_SKIP_COLOR $YAK_IGNORE_COLOR);
use base qw(Class::Accessor);

Readonly::Scalar my $FALSE => 0;
Readonly::Scalar my $TRUE  => 1;
Readonly::Scalar my $SUCCESS => 0;
Readonly::Scalar my $FAILURE => 1;
Readonly::Scalar my $OK  => 1;

use version; our $VERSION = version->declare('v1.0.0');
# HACK: I need to address these, I do not like the scoping
my $yak;
my $matcher;
my $directory_stack = Data::Stack->new();
my $files;

App::Yak->mk_accessors(qw(
    default_config_file
    default_checksums_src
    version
    verbose
    silent
    debug
    nodebug
    color
    nocolor
    emoji
    noemoji
    success_emoji
    failure_emoji
    skip_emoji
    ignore_emoji
    nochecksums
    checksums
    checksums_src
    noconfig
    config_src
    yakignores
    failure_color
    success_color
    skip_color
    ignore_color
));

sub new {
    my $class = shift;

    my $object = bless {}, $class;

    $object->version($VERSION);

    $object->default_config_file("$HOME/.config/yak/config.yml");
    $object->default_checksums_src("$HOME/.config/yak/checksums.json");

    $object->silent($FALSE);
    $object->verbose($FALSE);
    $object->nodebug($FALSE);
    $object->debug($FALSE);
    $object->nocolor($FALSE);
    $object->color($TRUE);
    $object->noemoji($FALSE);
    $object->emoji($TRUE);
    $object->nochecksums($FALSE);
    $object->noconfig($FALSE);

    $object->_set_emojis();
    $object->_set_colors();

    $yak = $object;

    return $object;
}

sub process {
    my ($self, $config) = @_;

    my $rv = $SUCCESS;

    $files = clone($self->checksums);

    if ($self->verbose) {
        $self->print_version;
    }

    my $yakignores = _set_yakignores($config);

    # Our global matcher
    $matcher = build_gitignore_matcher($yakignores);

    # Our stack of matchers to match assist our directory descend (preprocess) and ascend (postprocess)
    if ($matcher) {
        my ($current_directory) = getcwd() =~ m{/([\w-]+)$}; # we need the last part of the complete path
        $directory_stack->push({ directory => $current_directory, matcher => $matcher });
    }

    find({ wanted => \&_process, preprocess => \&_preprocess, postprocess => \&_postprocess }, qw(.));

    foreach my $not_found_file ( keys %{$files} ) {
        $self->print_failure($not_found_file);
        $rv = $FAILURE;
    }

    return $rv;
}

sub _process {
    $matcher->($_)
    && $yak->print_ignore($File::Find::name)
    && ($File::Find::prune = $TRUE)
    || $yak->subprocess($_);

    return $SUCCESS;
}

sub _preprocess {

    if (-e '.yakignore' and -f _ and -r _) {
        my @lines = read_lines('.yakignore');
        my $local_matcher = build_gitignore_matcher([@lines]);
        $directory_stack->push({ directory => $File::Find::dir, matcher => $local_matcher });
        $matcher = $local_matcher;

        if ($yak->debug) {
            say STDERR "_preprocess: Located .yakignore in $File::Find::dir";
        }
    }

    # REF: http://jonasbn.github.io/til/cpan/file-find.html
    return @_;
}

## no critic (RequireFinalReturn)
sub _postprocess {

    if (-e '.yakignore' and -f _ and -r _) {

        my $element = $directory_stack->peek();

        if ($element->{directory} eq $File::Find::dir) {
            $directory_stack->pop;
            $element = $directory_stack->pop;
            $matcher = $element->{matcher};
        }

        if ($yak->debug) {
            say STDERR "_postprocess: Located .yakignore in $File::Find::dir";
        }
    }
}
## use critic

sub subprocess {
    my ($self, $file) = @_;

    if ($self->debug) {
        say STDERR "subprocess: Asserting file: $file";
    }

    my $rv = $SUCCESS;

    if (any { $file eq $_ } keys %{$self->checksums} ) {

        my $checksum;
        my $assertion = $self->checksums->{$file};

        if ($assertion =~ m/file/i) {
            my ($filename) = $assertion =~ s{file:\/\/(.*)}{$1};
            $checksum = sha256_file_hex("$HOME/.config/yak/files/$assertion");
        } elsif ($assertion =~ m/http/i) {
            my $content = $self->_read_checksum_url($assertion);
            $checksum = sha256_hex($content);
        } elsif ($assertion eq $JSON::true and -f $file) {
            $self->print_presence_success($File::Find::name);
        } elsif ($assertion eq $JSON::false and -f $file) {
            $self->print_no_presence_success($File::Find::name);

        } elsif ($assertion eq $JSON::false and -f $file) {
            $self->print_presence_failure($File::Find::name);
            $rv = $FAILURE;

        } else {
            $checksum = $assertion;
        }

        if ($checksum) {
            my $file_checksum = sha256_file_hex($file);

            if ($file_checksum eq $checksum) {
                $self->print_match_success($File::Find::name);
            } else {
                $self->print_match_failure($File::Find::name);
                $rv = $FAILURE;
            }
        }
        delete $files->{$file};

    } elsif (-f $file and $self->verbose) {
        $self->print_skip($File::Find::name);
    }

    return $rv;
}

sub print_match_success {
    my ($self, $filename) = @_;

    $self->_print_success($filename . ' matches');

    return $OK;
}

sub print_no_presence_success {
    my ($self, $filename) = @_;

    $self->_print_success($filename . ' not present');

    return $OK;
}

sub print_presence_success {
    my ($self, $filename) = @_;

    $self->_print_success($filename . ' present');

    return $OK;
}


sub _print_success {
    my ($self, $message) = @_;

    unless ($self->silent) {
        if ($self->color) {
            print Term::ANSIColor::color($self->success_color);
            say $self->success_emoji . $message;
            print Term::ANSIColor::color('reset');
        } else {
            say $self->success_emoji . $message;
        }
    }

    return $OK;
}

sub print_skip {
    my ($self, $filename) = @_;

    unless ($self->silent) {
        if ($self->color) {
            print Term::ANSIColor::color($self->skip_color);
            say $self->skip_emoji . $filename . ' skipped';
            print Term::ANSIColor::color('reset');
        } else {
            say $self->skip_emoji, "$filename skipped";
        }
    }

    return $OK;
}

sub print_presence_failure {
    my ($self, $filename) = @_;

    $self->print_failure($filename . ' not present');

    return $OK;
}

sub print_match_failure {
    my ($self, $filename) = @_;

    $self->print_failure($filename . ' not matching');

    return $OK;
}

sub print_failure {
    my ($self, $message) = @_;

    unless ($self->silent) {
        if ($self->color) {
            print Term::ANSIColor::color($self->failure_color);
            say $self->failure_emoji . $message;
            print Term::ANSIColor::color('reset');
        } else {
            say $self->failure_emoji . $message;
        }
    }

    return $OK;
}

sub print_ignore {
    my ($self, $filename) = @_;

    unless ($self->silent) {
        if ($self->color) {
            print Term::ANSIColor::color($self->ignore_color);
            say $self->ignore_emoji . $filename . ' ignored';
            print Term::ANSIColor::color('reset');
        } else {
            say $self->ignore_emoji, "$filename ignored";
        }
    }

    return $OK;
}

sub print_version {
    my $self = shift;

    say 'yak : '.$self->version;

    return $SUCCESS;
}

sub emoji {
    my ($self, $emoji) = @_;

    if (defined $emoji) {
        if ($self->noemoji) {
            $self->{emoji} = $FALSE;
            $self->_reset_emojis;
        } else {
            if ($emoji) {
                $self->{emoji} = $TRUE;
                $self->_set_emojis;
            } else {
                $self->{emoji} = $FALSE;
                $self->_reset_emojis;
            }
        }
    }

    return $self->{emoji};
}

sub debug {
    my ($self, $debug) = @_;

    if (defined $debug) {
        if ($self->nodebug) {
            $self->{debug} = $FALSE;
        } else {
            $self->{debug} = $debug;
        }
    }

    return $self->{debug};
}

sub verbose {
    my ($self, $verbose) = @_;

    if (defined $verbose) {
        if ($self->silent) {
            $self->{verbose} = $FALSE;
        } else {
            $self->{verbose} = $verbose;
        }
    }

    return $self->{verbose};
}

sub noemoji {
    my ($self, $noemoji) = @_;

    if (defined $noemoji) {
        $self->{noemoji} = $noemoji;

        if (defined $self->{noemoji}) {
            $self->_reset_emojis;
        }
    }

    return $self->{noemoji};
}

sub _set_colors {
    my $self = shift;

    $self->failure_color('red');
    $self->success_color('green');
    $self->ignore_color('blue');
    $self->skip_color('blue');

    return $TRUE;
}

sub _set_emojis {
    my $self = shift;

    $self->success_emoji('👍🏻');
    $self->failure_emoji('❗️');
    $self->skip_emoji('  ');
    $self->ignore_emoji('  ');

    return $TRUE;
}

sub _reset_emojis {
    my $self = shift;

    $self->success_emoji('  ');
    $self->failure_emoji('  ');
    $self->skip_emoji('  ');
    $self->ignore_emoji('  ');

    return $TRUE;
}

sub color {
    my ($self, $color) = @_;

    if ($self->nocolor) {
        return $FALSE;
    }

    if (exists($ENV{CLICOLOR_FORCE}) && $ENV{CLICOLOR_FORCE} == $FALSE) {
        $self->{color} = $FALSE;
        return $FALSE;
    } elsif (exists($ENV{CLICOLOR_FORCE}) && $ENV{CLICOLOR_FORCE} != $FALSE) {
        # REF: https://metacpan.org/pod/Term::ANSIColor#NO_COLOR
        delete $ENV{NO_COLOR};
        $self->{color} = $TRUE;
        return $TRUE;
    }

    if (exists($ENV{NO_COLOR})) {
        $self->{color} = $FALSE;
        return $FALSE;
    }

    if (exists($ENV{CLICOLOR}) && $ENV{CLICOLOR} == $FALSE) {
        $self->{color} = $FALSE;
        return $FALSE;
    } elsif (exists($ENV{CLICOLOR}) && $ENV{CLICOLOR} != $TRUE) {
        $self->{color} = $TRUE;
        return $TRUE;
    }

    if (defined $color) {
        if ($self->nocolor) {
            $self->{color} = $FALSE;
        }
        $self->{color} = $color;
    }

    return $self->{color};
}

sub _set_yakignores {
    my $config = shift;

    my $yakignores = [];

    if ($config and $config->[0]->{yakignores}) {
        $yakignores = $config->[0]->{yakignores};
    }

    return $yakignores;
}

sub read_config {
    my ($self, $flags) = @_;

    my $config;

    my $config_file = $self->config_src;

    if ($config_file and (not -e $config_file or not -f _ or not -r _)) {
        carp "Specified configuration file: $config_file, does not exist, is not a file or cannot be read, attempting with defalt configuration file\n";
    }
    $config_file = $config_file?$config_file:$self->default_config_file();

    try {
        $config = YAML::Tiny->read($config_file);
    } catch {
        carp "Configuration file: $config_file, does not exist, is not a file or cannot be read\n";
        $config = YAML::Tiny->new();
    };

    $self->debug($self->_has_config('debug', $config,));
    $self->verbose($self->_has_config('verbose', $config));
    $self->color($self->_has_config('color', $config));
    $self->emoji($self->_has_config('emoji', $config));

    $self->debug($TRUE) if $flags->{debug};
    $self->verbose($TRUE) if $flags->{verbose};
    $self->color($TRUE) if $flags->{color};
    $self->emoji($TRUE) if $flags->{emoji};

    my $failure_emoji = _set_emoji('failure_emoji', $config);
    my $success_emoji = _set_emoji('success_emoji', $config);
    my $ignore_emoji  = _set_emoji('ignore_emoji', $config);
    my $skip_emoji    = _set_emoji('skip_emoji', $config);

    $self->failure_emoji($failure_emoji) if $failure_emoji;
    $self->success_emoji($success_emoji) if $success_emoji;
    $self->ignore_emoji($ignore_emoji) if $ignore_emoji;
    $self->skip_emoji($skip_emoji) if $skip_emoji;

    my $failure_color = _set_color('failure_color', $config);
    my $success_color = _set_color('success_color', $config);
    my $ignore_color  = _set_color('ignore_color', $config);
    my $skip_color    = _set_color('skip_color', $config);

    $self->failure_color($failure_color) if $failure_color;
    $self->success_color($success_color) if $success_color;
    $self->ignore_color($ignore_color) if $ignore_color;
    $self->skip_color($skip_color) if $skip_color;

    return $config;
}

sub read_environment {
    my $self = shift;

    # Setting colors from environment
    if ($yak->color) {
        $yak->failure_color($YAK_FAILURE_COLOR) if $YAK_FAILURE_COLOR;
        $yak->success_color($YAK_SUCCESS_COLOR) if $YAK_SUCCESS_COLOR;
        $yak->ignore_color($YAK_IGNORE_COLOR) if $YAK_IGNORE_COLOR;
        $yak->skip_color($YAK_SKIP_COLOR) if $YAK_SKIP_COLOR;
    }

    return $OK;
}

sub read_checksums {
    my $self = shift;

    my $checksums_file = '';
    my $checksums_url  = '';

    if ($self->nochecksums) {
        my $cwd = getcwd();
        $checksums_file = "$cwd/.yaksums.json";

        if ($yak->debug) {
            say STDERR "read_checksums: Located .yaksums.json in $cwd";
        }
    } else {

        if ($self->checksums_src and $self->checksums_src =~ m/^http/i) {
            $checksums_url = $self->checksums_src;
        } elsif ($self->checksums_src) {
            $checksums_file = $self->checksums_src;
        } else {
            $checksums_file = $self->default_checksums_src;
        }
    }

    my $checksums;

    if ($checksums_url) {
        my $content = $self->_read_checksums_url();
        $checksums = from_json($content);

        $self->checksums($checksums);

    } else {
        if ($checksums_file and (not -e $checksums_file or not -f _ or not -r _)) {
            croak 'No checksums file available, please specify either a checksum file in the configuration directory or in the designated directory';
        } else {
            my $checksum_json = read_text($checksums_file);

            $checksums = from_json($checksum_json);
        }

        $self->checksums($checksums);

        $self->checksums_src($checksums_file);
    }

    return $OK;
}

sub _read_checksum_url {
    my ($self, $url) = @_;

    my $content;

    my $ua = LWP::UserAgent->new;
    $ua->agent($self->version);

    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        $content = $res->content;
    } else {
        croak $res->status_line;
    }

    return $content;
}

sub _read_checksums_url {
    my $self = shift;

    return $self->_read_checksum_url($self->checksums_src);
}

sub _has_config {
    my ($self, $key, $config) = @_;

    if ($config and $config->[0]->{$key}) {
        if ($config->[0]->{$key} eq 'false') {
            return $FALSE;
        } elsif ($config->[0]->{$key} eq 'true') {
            return $TRUE;
        }
    } else {
        return $self->$key();
    }
}

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
sub print_help {
    my $self = shift;

    $self->print_version();
    say '';
    say 'Usage: yak [options]';
    say '';
    say 'Options:';
    say '';
    say '--debug: output debug information';
    say '--nodebug: disabling debug output, if configured';
    say '--verbose: more verbose output';
    say '--noconfig: ignore $HOME/.config/.yak/config.yml';
    say '--config <file>: specify alternative to $HOME/.config/.yak/config.yml';
    say '--silent: suppress all output and rely on return value';
    say '--nochecksums: ignore $HOME/.config/.yak/checksums.json and use local .yaksums';
    say '--checksums <file>: specify alternative to $HOME/.config/.yak/checksums.json';
    say '--nocolor: disable colorized output';
    say '--color: enable colorized output';
    say '--noemoji: disable emoji output';
    say '--emoji: enable emoji output';
    say '--about: emit configuration and invocation description';

    return $SUCCESS;
}
## critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

sub print_about {
    my ($self, $flags, $config) = @_;

    $self->print_version();
    say '';
    say 'Using environment';
    say "- \$CLICOLOR = $ENV{CLICOLOR}"             if exists $ENV{CLICOLOR};
    say "- \$NO_COLOR = $ENV{NO_COLOR}"             if exists $ENV{NO_COLOR};
    say "- \$CLICOLOR_FORCE = $ENV{CLICOLOR_FORCE}" if exists $ENV{CLICOLOR_FORCE};
    say '';
    if (not $flags->{noconfig} or $flags->{config_src}) {
        say "Using configuration located at: $self->{config_src}" if $self->{config_src};
        say 'Configured with:';
        say '- debug: '.$config->[0]->{debug} if $config->[0]->{debug};
        say '- verbose: '.$config->[0]->{verbose} if $config->[0]->{verbose};
        say '- color: '.$config->[0]->{color} if $config->[0]->{color};
        say '- emoji: '.$config->[0]->{emoji} if $config->[0]->{emoji};
        say '- success_color: '.$config->[0]->{success_color} if $config->[0]->{success_color};
        say '- failure_color: '.$config->[0]->{failure_color} if $config->[0]->{failure_color};
        say '- skip_color: '.$config->[0]->{skip_color} if $config->[0]->{skip_color};
        say '- ignore_color: '.$config->[0]->{ignore_color} if $config->[0]->{ignore_color};

        if ($config->[0]->{yakignores}) {
            say '- yakignores: ';
            foreach my $yakignore (@{$config->[0]->{yakignores}}) {
                say "  - $yakignore";
            }
        }
    }

    say '';
    say 'Using data source located at: '.$self->checksums_src if $self->checksums_src;
    say '';
    say 'Invoked with:';
    say '--debug'                             if $flags->{debug};
    say '--nodebug'                           if $flags->{nodebug};
    say '--verbose'                           if $flags->{verbose};
    say '--noconfig'                          if $flags->{noconfig};
    say "--config $flags->{config_src}"       if $flags->{config_src};
    say '--silent'                            if $flags->{silent};
    say '--nochecksums'                       if $flags->{nochecksums};
    say "--checksums $flags->{checksums_src}" if $flags->{checksums_src};
    say '--nocolor'                           if $flags->{nocolor};
    say '--color'                             if $flags->{color};
    say '--noemoji'                           if $flags->{noemoji};
    say '--emoji'                             if $flags->{emoji};
    say '--about'                             if $flags->{about};

    return $SUCCESS;
}

sub _set_emoji {
    my ($key, $config) = @_;

    return $config->[0]->{$key} || '';
}

sub _set_color {
    my ($key, $config) = @_;

    return $config->[0]->{$key} || '';
}

1;

__END__

=pod

=encoding UTF-8

=begin markdown

![CI GitHub Action status badge](https://github.com/jonasbn/perl-app-yak/actions/workflows/ci.yml/badge.svg)
![Spellcheck Action status badge](https://github.com/jonasbn/perl-app-yak/actions/workflows/spellcheck.yml/badge.svg)
![Markdownlint Action status badge](https://github.com/jonasbn/perl-app-yak/actions/workflows/markdownlint.yml/badge.svg)

The **yak** command line utility is still WIP and to be regarded as _alpha_ software, most features are working but it not ready for first official release

---

=end markdown

=head1 NAME

App::Yak - Application to help with yak shaving for Git repositories etc.

=head1 SYNOPSIS

    my $yak->new();
    my $rv = $yak->process();

=head1 DESCRIPTION

The B<yak> I<shaver> can scan a directory for files, which can be classified as yaks in need of shaving. Meaning files which are maintained else where are often copy-pasted.

The file names can be configured in a central configuration file, like this:

F<$HOME/.config/yak/checksums.json>

    {
        "CONTRIBUTING.md": "15701b6b27e1d49ca6636f2695cfc49b6622c7152f74b14becc53850811db54f"
    }

If a file is encountered, which matches the name, the checksum of the encountered file is calculated and is compared to the checksum listed in the central file.

=over

=item * If they match, everything is okay

=item * If they differ, the difference has to be addressed

=back

The recommendation is to have the checksum in the central file, reflect the authoritative revision and hence you can overwrite the file in the directory you where inspecting.

Alternatively to specifying a checksum, you can specify a file URL:

    {
        "MANIFEST.SKIP": "file://MANIFEST.SKIP"
    }

The file pointed to has to be available in: F<$HOME/.config/yak/files>

Then C<yak> can calculate the checksum dynamically, based on the reference file and can based on invocation copy the reference file to the location of the evaluated file in the case where the two differ.

=head2 CHECKSUM DATA FILE EXAMPLE

This JSON file should be created as C<$HOME/.config/yak/checksums.json>.

    {
        "CODE_OF_CONDUCT.md": "https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json",
        "CONTRIBUTING.md": "file://CONTRIBUTING.md",
        "PULL_REQUEST_TEMPLATE.md": "91dabee84afd46f93894d1a266a773f3d46c2c0b1ae4813f0c7dba34df1dc260",
        "MANIFEST.SKIP": "file://MANIFEST.SKIP"
    }

=head2 IGNORING CERTAIN DIRECTORIES, FILES AND FILENAME PATTERNS

C<yak> supports the ability to ignore:

=over

=item * Files

=item * Directories

=item * Filename patterns

=back

This is accomplished using an implementation based on C<.gitignore>. To not intervene and to let C<git> and C<yak> work in harmony. The files used by C<yak> are named C<.yakignore>.

The mean that you can:

=over

=item * Specify patterns of files and directories in your configuration file, see L</CONFIGURATION>. This configuration will be overwritten if the next options are used.

=item * You can add an C<.yakignore> in the root of your repository and it will work for all files and directories in the file structure beneath it. Do note that the presence of this files, ignores and configuration in regard to using this feature. Meaning that disabling C<yak> ignores for a single repository can be accomplished by placing an empty C<.yakignore> file in the root of the repository.

=item * a I<child> C<.yakignore> can be placed in a subsequent directory, working on all files and directories beneath it, do note that directories specified to be ignored in the I<parent> C<.yakignore> are ignored and are not parsed and used.

=back

=head2 YAK IGNORE FILE EXAMPLE

    .git
    local

The above example specified the C<local> directory created by Perl's Carton. Another good candidate could be the C<.git> folder.

Since C<yak> is processing a directory structure recursively, specifying directories should speed up the processing. Specifying single files by name can be used to skip a file specified in the data source file temporarily.

=head1 INVOCATION

C<yak> takes the following command line arguments:

=over

=item * C<--verbose>, enables more verbose output, can be configured see L</CONFIGURATION>

=item * C<--silent>, disables output and you have to rely on the return value see L</RETURN VALUES> below.

=item * C<--debug>, enables debug output. can be configured see L</CONFIGURATION>

=item * C<--nodebug>, disables debug output even if configured or provided as C<--debug>, see above

=item * C<--config file>, reads alternative configuration file instead of default, see L</CONFIGURATION>

=item * C<--noconfig>, disables reading of the configuration file, (see L</CONFIGURATION>) and you have to rely on the command line arguments

=item * C<--nochecksums>, disables reading of the global checksums file, see L</DATA SOURCE>

=item * C<--checksums file>, reads alternative checksums file instead of default, see L</DATA SOURCE>

=item * C<--color>, enables colorized output, enabled by default or can be configured, see L</CONFIGURATION>

=item * C<--nocolor>, disables colorized output, even if configured or provided as C<--color>, see above

=item * C<--emoji>, enables emojis in output, enabled by default or can be configured, see L</CONFIGURATION>

=item * C<--noemoji>, disables emojis in output, even if configured or provided as C<--emoji>, see above

=item * C<--about>, emits output on configuration and invocation and terminates with success

=item * C<--help>, emits help message listing all available options

=item * C<--version>, emits version message listing version of the software

=back

Command line arguments override the configuration.

=head2 RETURN VALUES

=over

=item * C<0>, success, everything is okay

=item * C<1>, failure, a located filed did not match the designated checksum

=back

Note that C<--about> return as success with out processing any data apart from reading configuration and parsing command line arguments.

=head1 ENVIRONMENT

C<yak> supports the following environment variables:

=over

=item * C<$CLICOLOR}>, if set to false (C<0>) it attempts to disable colorized output, if set to true (C<1>), it attempts to enable colorized output

=item * C<$NO_COLOR>, if set it attempts to disable colorized output, do note that value does not matter

=item * C<$CLICOLOR_FORCE>, if set to true (C<1>) it attempts to enable colorized output, if set to false (C<0>), it attempts to disable colorized output

=item * C<$YAK_SUCCESS_COLOR>, setting color for success messages, used when colors are enabled

=item * C<$YAK_FAILURE_COLOR>, setting color for failure messages, used when colors are enabled

=item * C<$YAK_SKIP_COLOR>, setting color for skip messages, used when colors are enabled

=item * C<$YAK_IGNORE_COLOR>, setting color for ignore messages, used when colors are enabled

=back

=head2 CLI Color Control

The order of precedence is as follows for CLI color control:

=over

=item 1. Environment (this section), C<$CLICOLOR_FORCE>

=item 2. Command line arguments, C<--nocolor> and C<--color> in that order, see L</INVOCATION>

=item 3. Environment (this section), C<$NO_COLOR>

=item 4. Environment (this section), C<$CLICOLOR>

=item 5. Configuration, see L</CONFIGURATION>, C<color> configuration option

=back

This aims to follow the proposed standard described in L<this article|https://bixense.com/clicolors/>.

=head2 Color Control

The order of precedence is as follows for color control:

=over

=item 1. Command line arguments, C<--nocolor> and C<--color> in that order, see L</INVOCATION>

=item 2. Environment (this section), C<$YAK_*_COLOR>

=item 3. Configuration, see L</CONFIGURATION>, colors configuration options: C<success_color>, C<failure_color>, C<skip_color> and C<ignore_color>

=back

Do note this works for the single environment variables, the command line arguments work generally.

=head1 CONFIGURATION

F<$HOME/.config/yak/config.yml>

C<yak> can be configured using the following parameters:

=over

=item * C<verbose>, enabling (C<true>) or disabling (C<false>) more verbose output

=item * C<debug>, enabling (C<true>) or disabling (C<false>) debug output

=item * C<color>, enabling (C<true>) or disabling (C<false>) colorized output

=item * C<emoji>, enabling (C<true>) or disabling (C<false>) colorized output

=item * C<success_emoji>, setting emoji for success messages, used when emojis are enabled

=item * C<failure_emoji>, setting emoji for failure messages, used when emojis are enabled

=item * C<skip_emoji>, setting emoji for skip messages, used when emojis are enabled

=item * C<ignore_emoji>, setting emoji for ignore messages, used when emojis are enabled

=item * C<success_color>, setting color for success messages, used when colors are enabled

=item * C<failure_color>, setting color for failure messages, used when colors are enabled

=item * C<skip_color>, setting color for skip messages, used when colors are enabled

=item * C<ignore_color>, setting color for ignore messages, used when colors are enabled

=item * C<yakignores>, specify a list of file directory names and patterns to be ignored

=back

Configuration can be overridden by command line arguments, see L</INVOCATION>.

=head2 EXAMPLE CONFIGURATION

This YAML file should be created as C<$HOME/.config/yak/config.yml>.

    verbose: false
    debug: false
    skip_emoji: ✖️
    failure_emoji: ❌
    success_emoji: ✅
    failure_color: yellow
    yakignores:
    - .git
    - local

=head1 DATA SOURCE

There are 3 ways to provide checksum data to C<yak>.

=over

=item * The default using: C<$HOME/.config/yak/checksums.json>, which can then be edited to match your needs

=item * Using a project or repository specific: C<.yaksums.json> located in the root of your project or repository directory

=item * Using an JSON file adhering to formatting described in this chapter, which can be located elsewhere on your file system

=back

The default data source is described in the L</DESCRIPTION>. As a an alternative a per project file can be specified in the designated repository/directory.

The file should be named: C<.yaksums.json>

The contents follow the same format as the C<$HOME/.config/yak/checksums.json>.

This JSON file should look as follows:

    {
        "<filename>": "<sha256 checksum for the file specifed by the filename>"
    }

An example:

    {
        "CODE_OF_CONDUCT.md": "https://gist.githubusercontent.com/jonasbn/dc331774eb67d067981902cadd3955ba/raw/b41de645c599be51e40a27e856333eeea261c12b/yaksums.json",
        "CONTRIBUTING.md": "file://CONTRIBUTING.md",
        "PULL_REQUEST_TEMPLATE.md": "91dabee84afd46f93894d1a266a773f3d46c2c0b1ae4813f0c7dba34df1dc260",
        "MANIFEST.SKIP": "file://MANIFEST.SKIP"
    }

If you want to have B<Yak> help you checking for the presence of a file, specify the I<boolean> C<true> instead of a checksum.

    {
        "ISSUE_TEMPLATE.md": true,
        "README.md": true
    }

Or you can issue an error if a file is present, which should not be there, again using a I<boolean>, but set to C<false>.

    {
        ".vstags": false
    }

=head1 COLORS

Terminal colors are awesome, but also not as easy to work with. B<yak> supports quite a few and relies on the implementation made available by L<Term::ANSIColor>, more options and more information is available, so please consult the L<Term::ANSIColor> documentation for more details.

=over

=item * C<black>

=item * C<red>, default for failure

=item * C<green>, default for success

=item * C<yellow>

=item * C<blue>, default for skip and ignore

=item * C<magenta>

=item * C<cyan>

=item * C<white>

=item * C<bright_black>

=item * C<bright_red>

=item * C<bright_green>

=item * C<bright_yellow>

=item * C<bright_blue>

=item * C<bright_magenta>

=item * C<bright_cyan>

=item * C<bright_white>

=item * C<faint>

=back

The default colors should be available in most terminals. The color C<faint> is not supported by all terminals, but looks truly awesome, please consult the L<Term::ANSIColor> documentation for compatibility details.

=head1 USING DOCKER

An experimental Docker implementation has been included with the repository.

It can be built using the following statement:

    $ docker build -t jonasbn/yak .

And then run as follows:

    $ docker run --rm -it -v $PWD:/tmp jonasbn/yak

It will consume all the command line arguments (see L</INVOCATION>).

The Docker image has the following command line arguments embedded:

=over

=item * C<--noconfig>

=item * C<--nochecksums>

=back

Since the ability to read files outside the Docker container is limited to mounted directories.

The mount point is expected to be a directory containing the files to be checked against the checksum data structure. Please see the L</LIMITATIONS> for details.

If you want to utilize the supported environment variables (see L</ENVIRONMENT>) you have to do something along the lines of:

    $ docker run --rm -it -v $PWD:/tmp --env CLICOLOR=$CLICOLOR jonasbn/yak

=head1 API

=head2 noemoji

=head2 print_about

=head2 print_failure

=head2 print_help

=head2 print_ignore

=head2 print_skip

=head2 print_success

=head2 print_version

=head2 process

=head2 read_checksums

=head2 read_config

=head2 read_environment

=head2 subprocess

=head2 print_match_failure

=head2 print_match_success

=head2 print_no_presence_success

=head2 print_presence_failure

=head2 print_presence_success

=head1 REQUIREMENTS AND DEPENDENCIES

C<yak> is specified to a minimum requirement of Perl 5.10, based on an analysis made using L<Perl::MinimumVersion>, implementation syntax requires Perl 5.8.0, so C<yak> I<could be made to work> for 5.8.0.

=over

=item * L<Clone|https://metacpan.org/pod/Clone>

=item * L<Crypt::Digest::SHA256|https://metacpan.org/pod/CryptX>

=item * L<Data::Dumper|https://metacpan.org/pod/Data::Dumper>

=item * L<Data::Stack|https://metacpan.org/pod/Data::Stack>

=item * L<Env|https://metacpan.org/pod/Env>

=item * L<File::Find|https://metacpan.org/pod/File::Find>

=item * L<File::Slurper|https://metacpan.org/pod/File::Slurper>

=item * L<Getopt::Long|https://metacpan.org/pod/Getopt::Long>

=item * L<JSON|https://metacpan.org/pod/JSON>

=item * L<List::MoreUtils|https://metacpan.org/pod/List::MoreUtils>

=item * L<LWP::UserAgent|https://metacpan.org/pod/LWP::UserAgent>

=item * L<Term::ANSIColor|https://metacpan.org/pod/Term::ANSIColor>

=item * L<Text::Gitignore|https://metacpan.org/pod/Text::Gitignore>

=item * L<version|https://metacpan.org/pod/version>

=item * L<YAML::Tiny|https://metacpan.org/pod/YAML::Tiny>

=back

=head1 LIMITATIONS

=over

=item * C<yak> is specified to a minimum requirement of Perl 5.10, based on an analysis made using L<Perl::MinimumVersion>, implementation syntax requires Perl 5.8.0, so C<yak> I<could be made to work> for 5.8.0.

=item * Running under Docker is limited to using only checksums specified in a local <.yaksums.json> and configuration has to be specified using command line arguments not a file

=item * The use of a local: C<.yaksums.json> is limited to checksums and cannot calculate based on files, since files are located in an unmounted directory

=item * The use of YAML implementation is based on L<YAML::Tiny|https://metacpan.org/pod/YAML::Tiny> and is therefor limited to this more simple implementation, which was however deemed sufficient for B<Yak>.

=item * C<yak> does currently not support symbolic links when doing file system traversal. The implementation is based on L<File::Find|https://metacpan.org/pod/File::Find> and support for symbolic links could be enabled, but has not been regarded as necessary for now.

=item * The parsing of C<.yakignore> files is based on L<Text::Gitignore|https://metacpan.org/pod/Text::Gitignore> and is limited to what this implementation supports, no known issues at this time.

=back

=head1 ISSUE REPORTING

If you experience any issues with B<yak> report these via GitHub. Please read L<the issue reporting template|https://github.com/jonasbn/perl-app-yak/blob/master/.github/ISSUE_TEMPLATE.md>.

=head1 DEVELOPMENT

If you want to contribute to B<yak> please read the L<Contribution guidelines|https://github.com/jonasbn/perl-app-yak/blob/master/CONTRIBUTING.md>
and follow L<the pull request guidelines|https://github.com/jonasbn/yak/blob/master/.github/PULL_TEMPLATE.md>.

=head2 CONTINUOUS INTEGRATION

The GitHub repository of B<perl-app-yak> was renamed from B<yak>. This broke the continuous integration setup with Travis CI. Therefore this has been disabled for now and instead an experimental CI based on GitHub Actions is used.

=over

=item * L<https://github.com/jonasbn/github-action-perl-dist-zilla>

=back

=head1 MOTIVATION

Much of what I do is yak shaving. For you who are not familiar with the term:

    "[MIT AI Lab, after 2000: orig. probably from a Ren & Stimpy episode.]
    Any seemingly pointless activity which is actually necessary to solve
    a problem which solves a problem which, several levels of recursion
    later, solves the real problem you're working on."

REF: L<The Jargon File|http://www.catb.org/~esr/jargon/html/Y/yak-shaving.html>

Used commonly for repetitive and boring work, required to reach a certain goal.

=head1 AUTHOR

=over

=item * jonasbn, L<website|https://jonasbn.github.io/>

=back

=head1 COPYRIGHT

C<yak> is (C) by Jonas Brømsø, (jonasbn) 2018-2022

L<Image|https://unsplash.com/photos/3b3O75X0Jzg> used on the B<yak> L<website|https://jonasbn.github.io/perl-app-yak/> is under copyright by L<Shane Aldendorff|https://unsplash.com/@pluyar>.

=head1 LICENSE

C<yak> is released under the MIT License

=head1 REFERENCES

=over

=item 1. GitHub: L<"The Yak Project"|https://jonasbn.github.io/yak/>

=item 2. MetaCPAN: L<TERM-ANSICOLOR|https://metacpan.org/pod/Term%3A%3AANSIColor>

=item 3. Bixsense: L<"Standard for ANSI Colors in Terminals"|https://bixense.com/clicolors/>

=item 4. NO_COLOR: L<"NO_COLOR"|https://no-color.org/>

=back

=cut
