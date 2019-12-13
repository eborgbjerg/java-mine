#!/usr/bin/perl
# Snippet to in-place edit a file.
# the file name is given on the command line
use strict;
use warnings FATAL => 'all';

# From 'Learning Perl' 7th Ed.
# Chapter 9. Processing Text with Regular Expressions

chomp(my $date = `date`);
$^I = ".bak";

while (<>) {
    s/\AAuthor:.*/Author: Randal L. Schwartz/;
    s/\APhone:.*\n//;
    s/\ADate:.*/Date: $date/;
    print;
}