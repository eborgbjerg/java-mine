#!/usr/bin/perl
# $ ./java-lint.pl /home/admin/git/chessshell-api-1/
use strict;
use warnings;
use v5.22;

my @source_dirs = @ARGV;

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
);

use File::Find;
sub finder {
    if (/\.java\Z/) {
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

