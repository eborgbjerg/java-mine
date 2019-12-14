#!/usr/bin/perl
# $ ./java-lint.pl /home/admin/git/chessshell-api-1/
use strict;
use warnings;
use v5.22;

my @source_dirs = @ARGV;


# todo configure which files are scanned
# todo post process after data accumulation



my @rules = (
    {   desc    =>  'equals override',
        regex   =>  qr/ public \s+ boolean \s+ equals \s* \(\s*Object/x,
    },
    {   desc    =>  'test of equals',
        regex   =>  qr/ EqualsVerifier \.forClass \((\w+)/x,
    },
    {   desc    =>  'danger of copy paste bug',
        regex   =>  qr/ \d+ \s*= \s*\w+ \d+/x,
    },
    {   desc    =>  'tabs in source code',
        regex   =>  qr/\t/,
    }
);

use File::Find;
sub finder {
    if (/\.java\Z/) {
        return if /_jmhTest/;
        open my $fh, '<', $_;
        my @lines = <$fh>;
        foreach my $rule (@rules) {
            my @matches = grep(/$rule->{regex}/, @lines);
            if (@matches) {
                print "$rule->{desc};;$_ ;;$matches[0]";
            }
        }
        close $fh;
    }
}

find(\&finder, @source_dirs);



