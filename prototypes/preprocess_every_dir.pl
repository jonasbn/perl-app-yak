#!/usr/bin/env perl

use strict;
use warnings;
use v5.10; # say
use File::Find; # find
use Data::Dumper;
use Text::Gitignore qw(match_gitignore build_gitignore_matcher);
use File::Slurper qw(read_lines);

my $matcher = build_gitignore_matcher([]);

find({ wanted => \&process, preprocess => \&preprocess }, $ARGV[0]);

exit 0;

sub process {
    $matcher->($_) && ($File::Find::prune = 1) || say STDERR "Examining: $_";

    #say 'we are in process';
    #say STDERR "Examining: $_";
    
    #if ($m->{matcher} and $m->{matcher}->($_)) {
    #    say "Please ignore: local";
    #} else {
    #    say "Proceed with $_";
    #}
}

sub preprocess {
    
    #say 'we are in preprocess';
    #say STDERR "Examining: $_";

    my @lines = ();

    if (-e '.yakignore' and -f _) {
        @lines = read_lines('.yakignore');
        say "Hurrah we found a yak in $File::Find::dir";
        $matcher = build_gitignore_matcher([@lines]);
        #$m->{matcher} = $matcher;
    }

    return @_;
}
