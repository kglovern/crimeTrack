#!/usr/bin/perl

#
# TODO:
#  - Everything
#

#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');
use Text::CSV  1.32;

#
#   Variables
#
my $COMMA = q{,};
my $fh;
my $queryFile;
my $startYear;
my $endYear;
my $questionType;
my $csv = Text::CSV->new ({sep_char => $COMMA});
#   Arrays
my @years = ();
my @queries;
my @records;
#   Hashes

#
# Read in command line query input
#
if ($#ARGV != 0) {
    print "No input specified\nUsage: query.pl <query input file>\n";
    exit;
} else {
    $queryFile = $ARGV[0];
}

open $fh, "<", $queryFile
    or die "Unable to open query file, exiting\n";

@queries = <$fh>;

close $fh;

#
# Determine what we're asking
#
foreach my $query ( @queries ) {
    if ($csv->parse ($query)) {
        my @fields = $csv->fields();
        $questionType = $fields[0];
        $startYear = $fields[1];
        $endYear = $fields[2];
    } else {
        exit;
    }
}

print "Question Type: $questionType\nStart Year: $startYear\nEnd Year: $endYear\n";

#
# Generate list of years to look at
#
while ($startYear <= $endYear) {
    push @years, $startYear;
    print "Pushing year $startYear\n";
    $startYear ++;
}
