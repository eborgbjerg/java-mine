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

my $method_end_tab    = qr/^\t}\s*$/;
my $method_end_spaces = qr/^ {2,4}}\s*$/;
my $start_brace_line  = qr/{\s*$/;

my $lambda_start = "() -> {\n";
my $lambda_end = "});\n";


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
    my $indent = '';

    open my $fh, '>', $filename if defined $commit;
    foreach my $line (@$lines) {

        my $line_before = $line;

        # todo
        # - remove public modifier from @Test methods and (optionally) from class name

        # todo
        #  - add imports if needed:
        #       import static org.junit.jupiter.api.Assertions.assertThrows;
        #       import static org.junit.jupiter.api.Assertions.assertTimeoutPreemptively;

        # todo
        # list unhandled stuff (collect in an error-list
        #   - parameterized tests: @RunWith(@Parameterized)
        #   - @Rule ?  @RunWith ?
        # import org.junit.runner.RunWith;
        # import org.junit.runners.Parameterized;
        # import org.junit.runners.Parameterized.Parameters;


        if (defined($timeout) and defined($exception)) { # exception + timeout
            if ($line =~ $method_end_spaces or $line =~ $method_end_tab) {
                print $fh $method_body  if defined $commit;
                print $fh $indent . $indent . $lambda_end if defined $commit;
                print $fh $indent . $indent . $lambda_end if defined $commit;
                undef $timeout;
                undef $exception;
                $method_body = '';
            }
            elsif ($method_body eq '' and $line =~ $start_brace_line) {     # method signature
                $method_body  = $indent . $indent . assert_timeout_start($timeout);
                $method_body .= $indent . $indent . assert_throws_start($exception);
            }
            else {
                $method_body .= $indent . $line;            # collect method body to print later
                $line = '';
            }
        }
        elsif (defined($timeout)) { # timeout
            if ($line =~ $method_end_spaces or $line =~ $method_end_tab) {
                print $fh $method_body  if defined $commit;
                print $fh $indent . $indent . $lambda_end if defined $commit;
                undef $timeout;
                undef $exception;
                $method_body = '';
            }
            elsif ($method_body eq '' and $line =~ $start_brace_line) {     # method signature
                $method_body = $indent . $indent . assert_timeout_start($timeout);
            }
            else {
                $method_body .= $indent . $line;            # collect method body to print later
                $line = '';
            }
        }
        elsif (defined($exception)) { # exception
            if ($line =~ $method_end_spaces or $line =~ $method_end_tab) {
                print $fh $method_body  if defined $commit;
                print $fh $indent . $indent . $lambda_end if defined $commit;
                undef $timeout;
                undef $exception;
                $method_body = '';
            }
            elsif ($method_body eq '' and $line =~ $start_brace_line) {     # method signature
                $method_body = $indent . $indent . assert_throws_start($exception);
            }
            else {
                $method_body .= $indent . $line;            # collect method body to print later
                $line = '';
            }
        }

        # fully qualified class names + annotation usage
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
            or $line =~ s/ \@Ignore                             /\@Disabled/xo
        ) {
            $line_count++;
            print "$filename:\n\t${line_before} \t\t-> $line" unless defined $commit;
        }
        elsif ($line =~ / \Qorg.junit\E /) {
            die "This line contains a package name that I can't handle: $line";
        }

        elsif ($line =~ / (\s*) \@Test (.*) /xo) {
            # Handle @Test parameters
            $indent = $1;
            my $rest = $2;
            unless ($rest =~ / \s* \/\/ /xo) { # line comment
                if ($rest =~ / timeout \s* = \s* (\d+) /xo) {
                    $timeout = $1;
                }
                if ($rest =~ / expected \s* = \s* (\w+) /xo) {
                    $exception = $1;
                }
                if (defined($exception) or defined($timeout)) {
                    print "$filename:\n\t${line_before} \t\t" unless defined $commit;
                    if (defined($exception)) {
                        print " -> expect the exception class $exception" unless defined $commit;
                    }
                    if (defined($timeout)) {
                        print " -> timeout by $timeout milliseconds" unless defined $commit;
                    }
                    say "" unless defined $commit;
                }
            }
            $line = $indent . "\@Test\n";
        }

        print $fh $line if defined $commit;
    }
    close $fh if defined $commit;
    $files_to_edit{$filename} = 1 if $line_count > 0;
}


sub assert_throws_start {
    return "assertThrows($_[0].class, $lambda_start";
}

sub assert_timeout_start {
    "assertTimeoutPreemptively(Duration.ofMillis($_[0]), $lambda_start";
}
