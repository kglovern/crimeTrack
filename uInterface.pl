#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Text::CSV;
use Scalar::Util qw(looks_like_number);
use List::Util qw( min max );
use version;   our $VERSION = qv('5.16.0');

#
# Variables
#
my $SEP = q{,};
my $dataLoc = "./data";
my $file = "";
my $qType = "";
my $sYear = 0;
my $eYear = 0;
my $input = "";
my $outputStr;
my $location = "";
my $geoCount = 0;
my $province;
my $loc;
my $csv = Text::CSV->new({ binary=>1 });
my $vioMin = 1;
my $locMin = 1;
# Arrays
my @violations;
my @locations;
my @provinces;
my @results;
# Hash Tables
my %locData;
my %vioData;
my $nextInput = -1;

#
# Subroutine Prototypes
#
sub getInput;
sub parseToHash;
sub loadLocs;
sub returnProvinceArr;
sub returnCityArr;
sub searchHash;
sub minWarning;
sub promptContinue;
sub getNumeric;
sub printHeader;

#
# Set output file based on command line args
#
if ($#ARGV != 0) {
   print "Usage: uInterface.pl <question output file>\n";
   exit;
} else {
   $file = $ARGV[0];
}

#
#
# Load in violation data
#
%vioData = parseToHash("data/vios.data");
%locData = loadLocs("data/locs.data");

#
# Header
#
printHeader();


#
# Main Menu
#
print "1) Is crime A increasing, decreasing, or staying the same?\n";
print "2) How does crime A rates compare to crime B rates in a certain geography?\n";
print "3) Is crime A higher/ lower/ the same in area B compared to Canadian average?\n";
print "4) In what province is crime A highest/ lowest?\n";

$qType = getNumeric("Select a question type", 1, 4);

$qType = int($qType); # no sneaky fractions

#
# We have some minimum violation/location values to check for based on question type
#
if ($qType == 4) {
}
#
# Get the data range for data start and end years
#
my ($dataStart, $dataEnd) = getYearRange();

# Get start year
while (! ($sYear =~ /^\d{4}$/x)) {
    $sYear = getInput("Please enter the start year (data available from $dataStart):");
    if (! ($sYear =~ /^\d{4}$/x)) {
      print "Not a valid year - expected format: NNNN\n";
    }
}
if ($sYear < $dataStart) {
   warn "Start year entered is earlier than data available for.  Defaulting to first available year ($dataStart)\n";
   $sYear = $dataStart;
}

# Get end year
while (! ($eYear =~ /^\d{4}$/x)) {
   $eYear = getInput("Please enter the end year (start year was $sYear, data availabe until $dataEnd):");
   if (! ($eYear =~ /^\d{4}$/x)) {
     print "Not a valid year - expected format: NNNN\n";
   }
}
if ($eYear > $dataEnd) {
   warn "End year entered is later than data available for.  Defaulting to last available year ($dataEnd)\n";
   $eYear = $dataEnd;
}


#
#START LOCATION
#
#checks to see if asking for location is necessary
#prints provinces and takes in answer
@provinces = returnProvinceArr(%locData); # Get list of Provinces from array

if ($qType != 4) {
   while ($#locations < ($locMin - 1) || $nextInput == 1) {
      print "\n\nSelect a location for this query.\n";
      minWarning ("This question type requires at least $locMin location(s)", @locations);
      print "Locations available:\n";

      for my $index (0 .. $#provinces) {
         printf "%d) %s\n", ($index + 1), $provinces[$index];
      }

      $input = getNumeric("Please select a province", 0, ($#provinces + 1));
      $province = $provinces[$input - 1];

      print "$province\n";
      # Give an option to pick a sub city if it exists
      if (!keys %{$locData{$province}}) {
         print "No sub locations in $province, defaulting to 'All'\n";
         push @locations, $province;
      } else {
         print "\nCities within $province:\n";
         binmode(STDOUT, ":encoding(utf8)");
         my @cities = returnCityArr($province, %locData);
         for my $index (0 .. $#cities) {
            printf "%d) %s\n", $index, $cities[int($index)];
         }
         $input = getNumeric("Enter a sub location", 0, ($#cities + 1));
         my $city = $cities[int($input)];
         if ($input == 0) {
            $loc = $province;
         } else {
            if ($city =~ /gatineau/i) { #Damnit Gatineau
               $loc = "$city, $province part";
            } else {
               print "$city\n";
               $loc = "$city, $province";
            }
         }
      push @locations, $loc;
      }
      if ($qType == 1) {
         $nextInput = promptContinue("location");
      } else {
         $nextInput = 0;
      }
   }
}

if ($qType == 3) {
   push @locations, "Canada";
}
if ($qType == 4) {
   for my $index (1.. $#provinces) {
      push @locations, $provinces[$index];
   }
}

#
#END LOCATION
#

#
# Crime Lookup
#
print "\n";
while ($#violations < ($vioMin - 1) || $nextInput == 1) {
   print "Select a violation to include in this query\n";
   minWarning("This question type requires at least $vioMin violation(s)", @violations);
   $input = getInput("Please enter a keyword to search for a violation:");
   @results = searchHash($input, %vioData);

   if ($#results >= 0) {

      print "\nTerms matching $input:\n";
      print "0) Search for a different violation\n";
      for my $index ( 0 .. $#results ) {
        print "0) Go back\n";
         printf "%d) %s\n", ($index + 1), $results[$index];
      }

      $input = getInput("Select the number corresponding to the violation:");
      if ($input == 0) {
         print "Returning to violation search\n";
      } elsif ($input > 0 && $input <= ($#results + 1)) {
         push @violations, $results[$input - 1];
      }
      elsif ($input != 0) {
         print "Invalid index\n";
      }
   } else {
       print "No results found\n";
   }
   if ($#violations >= $vioMin - 1) {
      $nextInput = promptContinue("violation");
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
my @uniqueLoc = do { my %seen; grep { !$seen{$_}++ } @locations }; # credit to Perl maven for this snippet
$geoCount = ($#uniqueLoc + 1);
$outputStr = $outputStr.$geoCount;

foreach my $loc ( @uniqueLoc ) {
   $outputStr = $outputStr.$SEP."\"".$loc."\"";
}

# Now add all the violations we're looking at
my @uniqueVio = do { my %seen; grep { !$seen{$_}++ } @violations }; # Credit to perl maven for this snippet
foreach my $violation ( @uniqueVio ) {
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
   foreach my $prov (sort keys %data) {
      push @arr, $prov;
   }
   return @arr;
}

sub returnCityArr {
   my ($prov, %data) = (@_);
   my @arr;
   push @arr, "All Locations";

   foreach my $city (sort keys %{$data{$prov}}) {
      push @arr, $city;
   }
   return @arr;
}

#
# Prints a warning about how many elements must be selected
# Usage: minWarning("message to be printed", @arr_to_count_fron
#
sub minWarning {
   my ($message, @data) = (@_);
   my $count = (@data) ? ($#data + 1) : 0;
   print "$message\n";
   print "You currently have $count";
   if ($count > 0) {
      print ": ";
      foreach my $element ( @data ) {
         print "$element ";
      }
      print "\n";
   }
   print "\n";
}

#
# Search a hash map and print any close matches
# Usage: searchHash("Search String", %hash_to_search)
#
sub searchHash {
    my ($searchTerm, %data) = (@_);
    my @matches;
    my @keys = sort keys %data;
    foreach my $key ( @keys ) {
        if ($key =~ /$searchTerm/i) {
            push @matches, $key;
        }
    }
    return @matches;
}

#
# Get a Yes/No Answer from the user
# usage: promptContinue("location")
#
sub promptContinue {
   my $message = shift;
   my $affirm = "";
   while (1) {
      $affirm = getInput("Did you want to add another $message (Yes/No)?");
      if ($affirm =~ /^y(es)?$/i) {
         return 1;
      } elsif ($affirm =~ /^no?$/i) {
         return 0;
      }
   }
}

#
# Forces the user to enter a numeric input within a particular range
# Usage: getNumeric("Message to display", minRangeInt, maxRangeInt);
#
sub getNumeric {
   my $message = shift;
   my $start = shift;
   my $end = shift;
   my $number;
   while (1) {
      $number = getInput($message);
      if (looks_like_number $number) {
         if ($number >= $start && $number <= $end) {
            return $number
         } else {
            print "Selected index out of bounds\n";
         }
      } else {
         print "Please enter a number between $start and $end\n";
      }
   }
   return $number;
}

#
# Return two integers corresponding to the earliest and latest year data we have
# usage: getYearRange();
#
sub getYearRange {
   my @dataYears;
   my $min;
   my $max;

   opendir my $dir, $dataLoc
      or die "Unable to open directory for reading\n";
   my @files = readdir($dir);
   foreach my $file ( @files ) {
      if ($file =~ /^[0-9]{4}Crime.csv/i) {
         $file =~ s/[^0-9]//g;
         push @dataYears, $file
      }
   }
   $min = min (@dataYears);
   $max = max (@dataYears);

   return ($min, $max);
}

#
# Prints header... pretty simple
# usage: printHeader();
#
sub printHeader {
    print "\n**************************************************************************\n";
    print "Welcome to Team Sarnias Crime Statistics Application\n";
    print "created by Quinton, Jackson, Kevin, and Mitchell.\n";
    print "This program looks at crime statistics and answers questions\n";
    print "posed by the user. Once the user asks a question, a pdf containing\n";
    print "the answer will be created and placed in the OUTPUT folder.\n";
    print "**************************************************************************\n\n";
}