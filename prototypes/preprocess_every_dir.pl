#!/usr/bin/env perl

use strict;
use warnings;
use v5.10; # say
use File::Find; # find
use Data::Dumper;


find({ wanted => \&process, preprocess => \&preprocess, postprocess => \&postprocess }, $ARGV[0]);

exit 0;

sub preprocess {
    say 'we are in preprocess';
    say STDERR "Examining: $File::Find::dir";

    return @_;
}

sub process {
    say 'we are in process';
    say STDERR "Examining: $File::Find::dir";
}

sub postprocess {
    say 'we are in postprocess';
    say STDERR "Examining: $File::Find::dir";
}
