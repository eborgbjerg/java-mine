#!/usr/bin/perl
# $ ./java-lint.pl /home/admin/git/chessshell-api-1/
use strict;
use warnings;
use v5.22;
use autodie;


my @source_dirs = @ARGV;


# todo configure which files are scanned
# todo move the rule set to a module
# todo keep the rule set in some type of database


my @rules = (
    {   id      =>  'JMR-1',
        desc    =>  'equals override',
        regex   =>  qr/ public \s+ boolean \s+ equals \s* \(\s*Object/x,
    },
    {   id      =>  'JMR-2',
        desc    =>  'test of equals',
        regex   =>  qr/ EqualsVerifier \.forClass \((\w+)/x,
    },
    {   id      =>  'JMR-3',
        desc    =>  'danger of copy paste bug',
        regex   =>  qr/ \d+ \s*= \s*\w+ \d+/x,
    },
    {   id      =>  'JMR-4',
        desc    =>  'tabs in source code',
        regex   =>  qr/\t/,
    },
    # https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a#21456918
    {   id      =>  'JMR-5',
        desc    =>  'password pattern',
        regex   =>  qr/^(?=\S*?[A-Z])(?=\S*?[a-z])(?=\S*?[0-9])(?=\S*?[^\w\s]).{8,}$/,
        # @SuppressWarnings("squid=Sxyz") will match
    },
);

use File::Find;
sub finder {
    if (/\.java|\.groovy\Z/) {
        return if /_jmhTest/;
        open my $fh, '<', $_;
        my @lines = <$fh>;
        foreach my $rule (@rules) {
            my @matches = grep(/$rule->{regex}/, @lines);
            if (@matches) {
                print "$rule->{id};;$rule->{desc};;$_ ;;$matches[0]";
            }
        }
        close $fh;
    }
}

find(\&finder, @source_dirs);



