#!/usr/bin/perl

use strict;
use warnings;
use Cwd qw(cwd getcwd);
use File::Spec;

chdir('t');

my $cwd = cwd();

print $cwd . "\n";

$cwd = getcwd();

print $cwd . "\n";

my $curdir = File::Spec->curdir();

print $curdir . "\n";

my $rootdir = File::Spec->rootdir();

print $rootdir . "\n";

my $updir = File::Spec->updir();

print $updir . "\n";

my $rel_path = File::Spec->abs2rel( $cwd ) ;

print $rel_path . "\n";

print $cwd =~ m{/(\w+)$};

exit 0;
