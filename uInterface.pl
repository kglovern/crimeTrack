#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;

#
# Variables
#
my $SEP = q{,};
my $file = "input.que";
my $qType = 0;
my $sYear = 0;
my $eYear = 0;
my $location;
my $locAmount = 1;
my $crimeAType = 0;
my $crimeBType = 0;
my $input;
my $outputStr;
my $geoCount = 1;
my $csv = Text::CSV->new({ binary=>1 });
use version;   our $VERSION = qv('5.16.0');
# Arrays
my @violations;
my @locations;
my @results;
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

#
# Crime Lookup
#
print "Please enter a keyword to search for a related violation\n";
chomp($input = <>);
@results = searchHash($input, %vioData);
if ($#results >= 0) {

   print "Terms matching $input:\n";
   for my $index ( 0 .. $#results ) {
      print (($index + 1).") $results[$index]\n");
   }

   print "Select the number corresponding to the violation\n";
   chomp($input = <>);
   if ($input >= 0 && $input <= ($#results + 1)) {
      push @violations, $results[$input - 1];
   } else {
      print "Invalid index\n";
   }
} else {
    print "No results found\n";
}
#
# End Crime Lookup
#

#
# Format output string for printing to file
#

push @locations, "Ontario";
# Initial information that's consistent across every question
$outputStr = $qType.$SEP.$sYear.$SEP.$eYear.$SEP;

# Now add location count and locations
$geoCount = $#locations + 1;
$outputStr = $outputStr.$geoCount;
foreach my $loc ( @locations ) {
   $outputStr = $outputStr.$SEP."\"".$loc."\"";
}

# Now add all the violations we're looking at
foreach my $violation ( @violations ) {
   $outputStr = $outputStr.$SEP."\"".$violation."\"";
}

# Output it to the file
open (my $fh, ">", $file)
    or die "Unable to open output file\n";

print $fh $outputStr;

close $fh;

###################################################################################################
#   Subroutines
###################################################################################################

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
    my @matches;
    while (my ($key, $value) = each (%data)) {
        if ($key =~ /$searchTerm/i) {
            push @matches, $key;
        }
    }
    return @matches;
}
