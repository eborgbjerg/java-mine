#!/usr/bin/perl -s
# This script can migrate the most common JUnit 4 elements to JUnit 5,
# assuming that the existing code is not-too-weirdly formatted.
#
# Example:
# To list potential changes:
# $ ./junit-migrate-4-to-5.pl /home/admin/git/chessshell-api-1/
# To actually make changes:
# $ ./junit-migrate-4-to-5.pl -commit=1 /home/admin/git/chessshell-api-1/
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
# say for keys %files_to_edit;
say scalar keys %files_to_edit, " files in all.";

=sub
JUnit 4 -> JUnit 5 for one file.
=cut
sub work_on_lines {
    my ($filename, $lines) = @_;
    my $line_count = 0;
    my $timeout = undef;
    my $exception = undef;
    my $method_body = '';

    open my $fh, '>', $filename if defined $commit;
    foreach my $line (@$lines) {

        my $line_before = $line;
        chomp $line_before;

        if (defined($exception)) {
            if ($line =~ / {0,4}}/ or $line =~ /\t}/) { # end of method
                print $fh $method_body  if defined $commit;
                print $fh "        });" if defined $commit;
                undef $exception;
                $method_body = '';
            }
            elsif ($line =~ /{$/) {
                $method_body = "assertThrows(${exception}.class, () -> {\n";
            }
            else {
                $method_body .= $line; # collect method body
                $line = '';
            }
        }

        # fully qualified class names, annotation usage
        elsif ($line =~ s/ \Qorg.junit.BeforeClass\E            /org.junit.jupiter.api.BeforeAll/xo
            or $line =~ s/ \Qorg.junit.Before\E                 /org.junit.jupiter.api.BeforeEach/xo
            or $line =~ s/ \Qorg.junit.AfterClass\E             /org.junit.jupiter.api.AfterAll/xo
            or $line =~ s/ \Qorg.junit.After\E                  /org.junit.jupiter.api.AfterEach/xo
            or $line =~ s/ \Qorg.junit.Test\E                   /org.junit.jupiter.api.Test/xo
            or $line =~ s/ \Qorg.junit.Ignore\E                 /org.junit.jupiter.api.Disabled/xo
            or $line =~ s/ \Qorg.junit.Assert.assertEquals\E    /org.junit.jupiter.api.Assertions.assertEquals/xo
            or $line =~ s/ \Qorg.junit.Assert.assertTrue\E      /org.junit.jupiter.api.Assertions.assertTrue/xo
            or $line =~ s/ \Qorg.junit.Assert.assertFalse\E     /org.junit.jupiter.api.Assertions.assertFalse/xo
            or $line =~ s/ \Qorg.junit.Assert.*\E               /org.junit.jupiter.api.Assertions.*/xo
            or $line =~ s/ \@BeforeClass                        /\@BeforeAll/xo
            or $line =~ s/ (\@Before) (\s+)                     /${1}Each${2}/xo  # avoid matching @BeforeEach, @BeforeAll
            or $line =~ s/ \@AfterClass                         /\@AfterAll/xo
            or $line =~ s/ (\@After) (\s+)                      /${1}Each${2}/xo  # avoid matching @AfterEach, @AfterAll
        ) {
            $line_count++;
            print "$filename:\n\t$line_before -> $line" unless defined $commit;
        }
        elsif ($line =~ / \Qorg.junit\E /) {
            die "This line contains a package name that I can't handle: $line";
        }

        # @Test parameters
        elsif ($line =~ / \s* \@Test (.*) /xo) {
            my $rest = $1;
            unless ($rest =~ / \s* \/\/ /xo) { # line comment
                if ($rest =~ / timeout \s* = (\d+) /xo) {
                    print "$filename:\n\t$line_before: -> TIMEOUT($1)\n" unless defined $commit;
                    $timeout = $1;
                    $line = "    \@Test\n";
                }
                if ($rest =~ / expected \s* = (\w+) /xo) {
                    print "$filename:\n\t$line_before: -> EXPECTED($1)\n" unless defined $commit;
                    $exception = $1;
                    $line = "    \@Test\n";
                }
            }
        }

        print $fh $line if defined $commit;
    }
    close $fh if defined $commit;
    $files_to_edit{$filename} = 1 if $line_count > 0;
}
