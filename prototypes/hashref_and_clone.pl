#!/usr/bin/env perl

use strict;
use warnings;
use Clone 'clone';

use Data::Dumper qw(Dumper);

my $fruits = {
    apple  => 1,
    orange => 1,
    grape  => 1
};

my $tutti_frutti = clone($fruits);

print $fruits;
print Dumper \$fruits;

print $tutti_frutti;
print Dumper \$tutti_frutti;

delete $tutti_frutti->{apple};

print Dumper \$fruits;

print Dumper \$tutti_frutti;
