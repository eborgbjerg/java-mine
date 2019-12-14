#!/usr/bin/perl
# $ ./java-improve.pl /home/admin/git/chessshell-api-1/
#use strict;
use warnings;
use v5.22;
use autodie;


# todo
# rule to replace TAB with 4 spaces



my @source_dirs = @ARGV;

use File::Copy;

use File::Find;
sub finder {
    if (/\.java\Z/) {
        # todo - bail out if .bak file already exists!

        open my $fh, '<', $_;
        my @lines = <$fh>;
        close $fh;
        &do_generics($_, \@lines);
    }
}

find(\&finder, @source_dirs);

sub do_generics {
    my ($filename, $lines) = @_;
    if (grep(/new ArrayList<\w+>/, @$lines)) {
        move($filename, "$filename.bak");  # todo  unless -f $filename
        open my $fh, '>', $filename;
        foreach my $line (@$lines) { ##  todo  generalize classname
            $line =~ s/new ArrayList<\w+>(\s*[,;])/new ArrayList<>$1/;
            print $fh $line;
        }
        close $fh;
    }
}
