#!/usr/bin/perl
# Use to understand data structures.
use strict;
use warnings;
use v5.22;
use Data::Dumper;

my @rules = (

    {
        'desc' => 'equals override',
        'regex' =>
        qr/public\s+boolean\s+equals/,

    }
);

print Dumper(\@rules);

foreach my $rule (@rules) {
    print Dumper($rule);

    say $rule->{'regex'};
    say $rule->{'desc'};
}

