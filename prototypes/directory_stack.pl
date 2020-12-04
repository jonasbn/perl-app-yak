#!/usr/bin/env perl

use strict;
use warnings;
use v5.10; # say
use File::Find; # find
use Data::Dumper;

my $directory_stack = {};

find({ wanted => \&process, preprocess => \&preprocess, postprocess => \&postprocess }, $ARGV[0]);

exit 0;

sub preprocess {
    say 'we are in preprocess';
    say "Examining: $File::Find::dir";

    if (-e '.yakignore' and -f _) {
        say "We found a .yakignore file at: $File::Find::dir changing context";
        $directory_stack->{$File::Find::dir}++;
    }

    return @_;
}

sub process {
    say 'we are in process';
    say "Examining: $File::Find::dir";

    say Dumper $directory_stack;
}

sub postprocess {
    say 'we are in postprocess';
    say "Examining: $File::Find::dir";

    if (exists $directory_stack->{$File::Find::dir}) {
        say "We are out of .yakignore file context for $File::Find::dir changing context";
    }
}
