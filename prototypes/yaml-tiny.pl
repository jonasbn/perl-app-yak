#!/usr/bin/env perl

use warnings;
use strict;

use YAML::Tiny;
use Data::Dumper;

my $yaml = YAML::Tiny->new( { wibble => "wobble" } );

print "Populated:\n", Dumper $yaml;

$yaml = YAML::Tiny->new();

print "Unpopulated:\n", Dumper $yaml;

exit 0;
