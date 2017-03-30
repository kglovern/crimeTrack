#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;

#
# Variables
#
my $SEP = q{,};
my $file = $ARGV[0];
my $qType = 0;
my $sYear = 0;
my $eYear = 0;
my $input;
my $outputStr;
my $location = "";
my $geoCount = 0;
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
sub getInput;
sub parseToHash;
sub searchHash;
sub nixAccents;

#
# Load in violation data
#
%vioData = parseToHash("data/vios.data");

#
# Header - Some sort of welcome message
#

#
# Main Menu
#
print "1) How does crime A compare to crime B?\n";
print "2) Is crime A increasing, decreasing, or staying the same?\n";
print "3) Is crime A higher/ lower/ the same in area B compared to Canadian average?\n";
print "4) In what province is crime A highest/ lowest?\n";
while ($qType < 1 || $qType > 4) {
   $qType = getInput("Please choose a question type:");
   if ($qType < 1 && $qType > 4) {
      print "Not a valid question type\n";
   }
}

# Get start year
while (! ($sYear =~ /\d{4}/)) {
    $sYear = getInput("Please enter the start year.");
    if (! ($sYear =~ /\d{4}/)) {
      print "Not a valid year - expected format: NNNN\n";
    }
}

# Get end year
while (! ($eYear =~ /\d{4}/)) {
   $eYear = getInput("Please enter the end year");
   if (! ($eYear =~ /\d{4}/)) {
     print "Not a valid year - expected format: NNNN\n";
   }
}

#
#		LOCATION WILL LATER BE CHANGED
#
print "Please enter the location\n";
chomp($location = <STDIN>);
#
#		LOCATION WILL LATER BE CHANGED
#

#
# Crime Lookup
#

$input = getInput("Please enter a keyword to search for a related violation");

@results = searchHash($input, %vioData);
while (! @violations ) {
   if ($#results >= 0) {

      print "\nTerms matching $input:\n";
      for my $index ( 0 .. $#results ) {
         printf "%d) %s\n", ($index + 1), $results[$index];
      }

      $input = getInput("Select the number corresponding to the violation");
      if ($input >= 0 && $input <= ($#results + 1)) {
         push @violations, $results[$input - 1];
      } else {
         print "Invalid index\n";
      }
   } else {
       print "No results found\n";
   }
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
# Force the user to enter something that's not an empty string, and return the result
# Usage: getInput("Message to print");
#
sub getInput {
   my $message = shift;
   my $result = "";
   while ($result eq "") {
      print "$message\n";
      chomp($result = <STDIN>);
   }
   return $result
}

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

#
# Return a string with the vowels being fuzzy for accented char searching
# Usage: nixAccents("string to remove accents from");
#
sub nixAccents {
   my $input = shift;
   $input =~ s/[^a-z]/\*/gi;
   return $input;
}
