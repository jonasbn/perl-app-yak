package App::Yak;

use strict;
use warnings;
use v5.10; # say
           # stacked file tests, REF: https://perldoc.perl.org/functions/-X
use utf8;
use Carp;
use YAML::Tiny;
use JSON; # from_json
use Term::ANSIColor qw(:constants);
use Crypt::Digest::SHA256 qw(sha256_file_hex); # Provided by CryptX
use List::MoreUtils qw(any);
use Data::Stack;
use Text::Gitignore qw(match_gitignore build_gitignore_matcher);
use Cwd; # getcwd
use File::Find; # find
use File::Slurper qw(read_lines);

use Env qw($HOME);
use base qw(Class::Accessor);

use constant FALSE => 0;
use constant TRUE  => 1;
use constant SUCCESS => 0;
use constant FAILURE => 1;

our $VERSION = '1.0.0';

my $yak;
my $matcher;
my $directory_stack = new Data::Stack();

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
    config_src
));

sub new {
    my $class = shift;

    my $object = bless {}, $class;
    
    $object->version($VERSION);

    $object->default_config_file("$HOME/.config/yak/config.yml");
    $object->default_checksums_src("$HOME/.config/yak/checksums.json");

    $object->silent(FALSE);
    $object->verbose(FALSE);
    $object->nodebug(FALSE);
    $object->debug(FALSE);
    $object->nocolor(FALSE);
    $object->color(TRUE);
    $object->noemoji(FALSE);
    $object->emoji(TRUE);
    $object->nochecksums(FALSE);

    $object->success_emoji('👍🏻');
    $object->failure_emoji('❗️');
    $object->skip_emoji('  ');
    $object->ignore_emoji('  ');
    
    $yak = $object;

    return $object;    
}

sub process {
    my ($self, $config) = @_;

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

    return SUCCESS;
}

sub _process {
    $matcher->($_)
    && $yak->print_ignore($File::Find::name)
    && ($File::Find::prune = TRUE)
    || $yak->subprocess($_);

    return SUCCESS;
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

sub subprocess {
    my ($self, $file) = @_;

    my $rv = SUCCESS;

    if (-f $file and any { $file eq $_ } keys %{$self->checksums} ) {

        my $checksum;
        my $assertion = $self->checksums->{$file};

        if ($assertion =~ m/file/i) {
            my ($filename) = $assertion =~ s{file:\/\/(.*)}{$1};
            $checksum = sha256_file_hex("$HOME/.config/yak/files/$assertion");
        } elsif ($assertion eq $JSON::true) {
            $self->print_success($File::Find::name);
        } elsif ($assertion eq $JSON::false) {
            $self->print_failure($File::Find::name);
            $rv = FAILURE;

        } else {
            $checksum = $assertion;
        }

        if ($checksum) {
            my $file_checksum = sha256_file_hex($file);

            if ($file_checksum eq $checksum) {
                $self->print_success($File::Find::name);
            } else {
                $self->print_failure($File::Find::name);
                $rv = FAILURE;
            }
        }

    } elsif (-f $file and $self->verbose) {
        $self->print_skip($File::Find::name);
    }

    return $rv;
}

sub print_success {
    my ($self, $filename) = @_;

    unless ($self->silent) {
        if ($self->color) {
            say GREEN, $self->success_emoji . $filename . RESET;
        } else {
            say $self->success_emoji . $filename;
        }
    }
}

sub print_skip {
    my ($self, $filename) = @_;

    unless ($self->silent) {
        if ($self->color) {
            say FAINT, $self->skip_emoji . "$filename skipped", RESET;
        } else {
            say $self->skip_emoji, "$filename skipped";
        }
    }
}

sub print_failure {
    my ($self, $filename) = @_;

    unless ($self->silent) {
        if ($self->color) {
            say RED, $self->failure_emoji . $filename . RESET;
        } else {
            say $self->failure_emoji . $filename;
        }
    }
}

sub print_ignore {
    my ($self, $filename) = @_;

    unless ($self->silent) {
        if ($self->color) {
            say FAINT, $self->ignore_emoji . "$filename ignored", RESET;
        } else {
            say $self->ignore_emoji, "$filename ignored";
        }
    }
}

sub print_version {
    my $self = shift;

    say 'yak : '.$self->version;    
}

sub emoji {
    my ($self, $emoji) = @_;

    if ($emoji) {
        if ($self->noemoji) {
            $self->{emoji} = FALSE;
        } else {
            $self->{emoji} = $emoji;
        }
    }

    return $self->{emoji};
}

sub debug {
    my ($self, $debug) = @_;

    if ($debug) {
        if ($self->nodebug) {
            $self->{debug} = FALSE;
        } else {
            $self->{debug} = $debug;
        }
    }

    return $self->{debug};
}

sub verbose {
    my ($self, $verbose) = @_;

    if ($verbose) {
        if ($self->silent) {
            $self->{verbose} = FALSE;
        } else {
            $self->{verbose} = $verbose;
        }
    }

    return $self->{verbose};
}

sub noemoji {
    my ($self, $noemoji) = @_;

    if ($noemoji) {
        $self->{noemoji} = $noemoji;

        if (not $self->{noemoji}) {
            $self->success_emoji('');
            $self->failure_emoji('');
            $self->skip_emoji('');
            $self->ignore_emoji('');
        }
    }

    return $self->{noemoji};
}

sub color {
    my ($self, $color) = @_;

    if (exists($ENV{CLICOLOR_FORCE}) && $ENV{CLICOLOR_FORCE} == FALSE) {
        $self->{color} = FALSE;
        return FALSE;
    } elsif (exists($ENV{CLICOLOR_FORCE}) && $ENV{CLICOLOR_FORCE} != FALSE) {
        $self->{color} = TRUE;
        return TRUE;
    }

    if (exists($ENV{CLICOLOR}) && $ENV{CLICOLOR} == FALSE) {
        $self->{color} = FALSE;
        return FALSE;
    } elsif (exists($ENV{CLICOLOR}) && $ENV{CLICOLOR} != TRUE) {
        $self->{color} = TRUE;
        return TRUE;
    }

    if ($color) {
        if ($self->nocolor) {
            $self->{color} = FALSE;
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
    my ($self) = @_;

    my $config;

    my $config_file = $self->config_src;

    if ($config_file and (not -e $config_file or not -f _ or not -r _)) {
        croak "Specified configuration file: $config_file, does not exist, is not a file or cannot be read";
    }
    $config_file = $config_file?$config_file:$self->default_config_file();

    if ($config_file and not -e $config_file or not -f _ or not -r _) {
        croak "Specified configuration file: $config_file, does not exist, is not a file or cannot be read";
    }

    $config = YAML::Tiny->read($config_file);

    return $config;
}

sub read_checksums {
    my $self = shift;

    my $checksums_file = '';

    if ($self->nochecksums) {
        my $cwd = getcwd();
        $checksums_file = "$cwd/.yaksums.json";
    } else {

        if ($self->checksums_src) {
            $checksums_file = $self->checksums_src;
        } else {
            $checksums_file = $self->default_checksums_src;
        }
    }

    my $checksums;

    if ($checksums_file and (not -e $checksums_file or not -f _ or not -r _)) {
        die 'No checksums file available, please specify either a checksum file in the configuration directory or in the designated directory';
    } else {
        open (my $checksums_fh, '<', $checksums_file) or die "Unable to read checksum file: $checksums_file - $!";
        my $checksum_json = join '', <$checksums_fh>;
        close $checksums_fh;

        $checksums = from_json($checksum_json);
    }

    $self->checksums($checksums);

    $self->checksums_src($checksums_file);

    return;
}

sub _is_config_true {
    my ($config, $key) = @_;

    if ($config and $config->[0]->{$key}) {
        return $config->[0]->{$key} eq 'true'?TRUE:FALSE;
    } else {
        return FALSE;
    }
}

sub _is_config_false {
    my ($config, $key) = @_;

    if ($config and $config->[0]->{$key}) {
        return $config->[0]->{$key} eq 'false'?TRUE:FALSE;
    } else {
        return FALSE;
    }
}

sub print_help {
    say "yak version $VERSION";
    say '';
    say 'yak [options]';
    say '';
    say 'Options';
    say '';
    say '--debug: debug output';
    say '--nodebug: disabling debug output, if configured';
    say '--verbose: more verbose output';
    say '--noconfig: ignore \$HOME/.config/.yak/config.yml';
    say '--config <file>: specify alternative to \$HOME/.config/.yak/config.yml';
    say '--silent: suppress all output and rely on return value';
    say '--nochecksums: ignore \$HOME/.config/.yak/checksums.json and use local .yaksums';
    say '--checksums <file>: specify alternative to \$HOME/.config/.yak/checksums.json';
    say '--nocolor: disable colorized output';
    say '--color: enable colorized output';
    say '--noemoji: disable emoji output';
    say '--emoji: enable emoji output';
    say '--about: emit configuration and invocation description';    

    return;
}

sub print_about {
    my ($self, $flags, $config) = @_;

    say 'yak version '.$self->version;
    say '';
    say 'Using environment';
    say "- \$CLICOLOR = $ENV{CLICOLOR}"             if exists $ENV{CLICOLOR};
    say "- \$CLICOLOR_FORCE = $ENV{CLICOLOR_FORCE}" if exists $ENV{CLICOLOR_FORCE};
    say '';
    if (not $flags->{noconfig}) {
        say "Using configuration located at: $self->{config_src}" if $self->{config_src};
        say 'Configured with:';
        say '- debug: '.$config->[0]->{debug} if $config->[0]->{debug};
        say '- verbose: '.$config->[0]->{verbose} if $config->[0]->{verbose};
        say '- color: '.$config->[0]->{color} if $config->[0]->{color};
        if ($config->[0]->{yakignores}) {
            say '- yakignores: ';
            foreach my $yakignore (@{$config->[0]->{yakignores}}) {
                say "  - $yakignore";
            }
        }
    }
    say '';
    say "Using data source located at: ".$self->checksums_src if $self->checksums_src;
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

    return SUCCESS;
}

sub _set_emoji {
    my ($key, $config) = @_;

    return $config->[0]->{$key} || '';
}

1;

# ABSTRACT: turns baubles into trinkets
