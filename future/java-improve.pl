#!/usr/bin/perl -s
# Example:
# To list potential changes:
# $ ./java-improve.pl           /home/admin/git/chessshell-api-1/
# To actually make changes:
# $ ./java-improve.pl -commit=1 /home/admin/git/chessshell-api-1/
use strict;
use warnings;
use v5.22;
use autodie;

our $commit;

my %files_to_edit;

my @source_dirs = @ARGV;

use File::Find;
sub finder {
    if (/\.java\Z/) {
        open my $fh, '<', $_;
        my @lines = <$fh>;
        close $fh;
        &work_on_lines($_, \@lines);
    }
}

find(\&finder, @source_dirs);

say '=' x 80;
say for keys %files_to_edit;
say scalar keys %files_to_edit, " files in all.";

=sub
Make substitutions in one file.
=cut
sub work_on_lines {
    my ($filename, $lines) = @_;
    my $line_count = 0;
    open my $fh, '>', $filename if defined $commit;
    foreach my $line (@$lines) {

        # use a list of functions here

        if ($line =~ s/ new \s+ (\w+) <\w+> \( \) (\s*[,;]) /new $1<>()$2/x) {
            print "$filename: Generics: $line";
            $line_count++;
        }
        if ($line =~ s/ \t /    /x) {
            print "$filename: TAB: $line";
            $line_count++;
        }
        print $fh $line if defined $commit;
    }
    close $fh if defined $commit;
    $files_to_edit{$filename} = 1 if $line_count > 0;
}
