#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;

#
# Variables
#
my $file = "outputfile.txt";
my $qType = 0;
my $sYear = 0;
my $eYear = 0;
my $location;
my $locAmount = 1;
my $crimeAType = 0;
my $crimeBType = 0;
my $csv = Text::CSV->new({ binary=>1 });
use version;   our $VERSION = qv('5.16.0');
# Arrays
my @crimeTypes = ("first degree murder", "second degree murder", "manslaughter", "attempted murder");
# Hash Tables
my %locData;
my %vioData;

#
# Subroutine Prototypes
#
sub parseToHash;
sub searchHash;
#
# Load in violation data
#
%vioData = parseToHash("data/vios.data");

open (my $fh, ">", $file)
    or die "Unable to open output file\n";

print "Please choose a question type.\n";
print "1. How does crime A compare to crime B?\n";
print "2. Is crime A increasing, decreasing, or staying the same?\n";
print "3. Is crime A higher/ lower/ the same in area B compared to Canadian average?\n";
print "4. In what province is crime A highest/ lowest?\n";
chomp($qType =  <>);
while ($qType < 1 || $qType > 4) {
    print "Incorrect entry, try again.\n";
    chomp($qType = <>);
}

if ($locAmount < 1 || $locAmount > 4) {
    $locAmount = 2;
}

print "Please enter the start year.\n";
chomp($sYear = <>);
while ($sYear < 1998 || $sYear > 2015) {
    print "Sorry, we do not have data for that year, try again.\n";
    chomp($sYear = <>);
}

print "Please enter the end year. To look only at the start year, print any number less than it.\n";
chomp($eYear = <>);
if ($eYear < $sYear) {
    $eYear = $sYear;
}
while ($eYear > 2015) {
    print "Sorry, we do not have data for that year, try again.\n";
    chomp($eYear = <>);
}

#
#		LOCATION WILL LATER BE CHANGED
#
print "Please enter the location\n";
chomp($location = <>);
#
#		LOCATION WILL LATER BE CHANGED
#

print "Please enter a keyword for crime A, all possible crimes will be displayed.\n";
chomp($crimeAType = <>);
foreach my $crime (@crimeTypes) {
    print "$crime\n";
}

if ($qType == 1) {
    print "Please enter the type of crime for crime B.\n";
    print "1. Violent crime\n";
    print "2. Traffic violations\n";
    print "3. Federal statute crimes\n";
    print "4. Drug violations\n";
    chomp($crimeBType = <>);
    while ($crimeBType < 1 || $crimeBType > 4) {
        print "Incorrect entry, try again.\n";
        chomp($crimeBType = <>);
    }
}

if ($qType == 4) {
    print $fh $qType.",".$sYear.",".$eYear.",".$locAmount.",".$location.",\"".$crimeAType."\",\"".$crimeBType."\"";
}
else {
    print $fh $qType.",".$sYear.",".$eYear.",".$locAmount.",".$location.",\"".$crimeAType."\"";
}

close $fh;

#
# Return a hash map from a specified file
# Usage: parseToHash("File Location");
#
sub parseToHash {
    my $inFile = shift;
    my $fh;
    my %dataHash;
    my @records;

    open $fh, "<", $inFile
        or die "Unable to open $inFile for parsing\n";
    while (my $line = <$fh>) {
        if ($csv->parse($line)) {
            my @fields = $csv->fields();
            $dataHash{$fields[0]} = $fields[1];
        } else {
            warn "Unable to parse line $line\n";
        }

    }
    close $fh;

    return %dataHash;
}
#
# Search a hash map and print any close matches
# Usage: searchHash("Search String", %hash_to_search)
#
sub searchHash {
    my ($searchTerm, %data) = (@_);
    while (my ($key, $value) = each (%data)) {
        if ($key =~ /$searchTerm/i) {
            print (($value+1).") $key\n");
        }
    }
}
