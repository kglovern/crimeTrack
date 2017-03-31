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
my $input = "";
my $outputStr;
my $location = "";
my $geoCount = 0;
my $province;
my $locFile = "data/locs.data";
my $csv = Text::CSV->new({ binary=>1 });
use version;   our $VERSION = qv('5.16.0');
# Arrays
my @violations;
my @locations;
my @provinces;
my @records;
my @results;
# Hash Tables
my %locData;
my %vioData;

#
# Subroutine Prototypes
#
sub getInput;
sub parseToHash;
sub loadLocs;
sub returnProvinceArr;
sub returnCityArr;
sub searchHash;
sub nixAccents;

#
# Load in violation data
#
%vioData = parseToHash("data/vios.data");
%locData = loadLocs("data/locs.data");

#
# Header - Some sort of welcome message
#

#
# Main Menu
#
print "1) Is crime A increasing, decreasing, or staying the same?\n";
print "2) How does crime A rates compare to crime B rates in a certain geography?\n";
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
    $sYear = getInput("Please enter the start year:");
    if (! ($sYear =~ /\d{4}/)) {
      print "Not a valid year - expected format: NNNN\n";
    }
}

# Get end year
while (! ($eYear =~ /\d{4}/)) {
   $eYear = getInput("Please enter the end year:");
   if (! ($eYear =~ /\d{4}/)) {
     print "Not a valid year - expected format: NNNN\n";
   }
}

#
#START LOCATION
#
#prints provinces and takes in answer
print "\n\nProvinces available:\n";
@provinces = returnProvinceArr(%locData); # Get list of Provinces from array

while (! @locations) {
   for my $index (0 .. $#provinces) {
      printf "%d) %s\n", ($index + 1), $provinces[$index];
   }
   $input = getInput("Please select a province:");
   $province = $provinces[$input - 1];
   print "$province\n";
   # Give an option to pick a sub city if it exists
   if (!keys $locData{$province}) {
      print "No sub locations with $province, defaulting to entire province\n";
      push @locations, $province;
   } else {
      print "\nCities within $province:\n";

      my @cities = returnCityArr($province, %locData);
      for my $index (0 .. $#cities) {
         printf "%d) %s\n", $index, $cities[$index];
      }
      $input = getInput("Please select a sub location");
      my $city = $cities[$input-1];
      my $loc = "$city, $province";
      push @locations, $loc;

   }
}


#
#END LOCATION
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
# Return a hash map consisting of the imported locations - sorted by province
# Usage: %myHash = loadLocs("Path/To/Loc/File");
#
sub loadLocs {
   my $inFile = shift;
   my $fh;
   my $province = "";
   my %dataHash;
   my @records;

   open $fh, "<", $inFile
      or die "Unable to open location data for parsing\n";

   while (my $line = <$fh>) {
         if ($csv->parse($line)) {
            my @fields = $csv->fields();
            if ($#fields == 0) { # got us a province
               $province = $fields[0];
               if (!exists $dataHash{$province}) {
                  $dataHash{$province} = {};
               }
            } else { # got us a city
                  $dataHash{$province}{$fields[0]} = $fields[1];
            }
         } else {
            warn "Unable to parse line $line\n";
         }
   }

   close $fh;

   return %dataHash;
}

#
# returnProvinceArr
#
#
sub returnProvinceArr {
   my %data = @_;
   my @arr;
   push @arr,"Canada";
   foreach my $province (sort keys %data) {
      push @arr, $province;
   }
   return @arr;
}

sub returnCityArr {
   my ($prov, %data) = (@_);
   my @arr;
   push @arr, "All Locations";
   while (my ($key, $value) = each %data->{$prov}) {
      push @arr, $key;
   }
   return @arr;
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
   my $string = shift;
   $string =~ s/[^a-z]/\*/gi;
   return $string;
}
