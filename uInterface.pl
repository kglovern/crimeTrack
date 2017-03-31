#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;

#
# Variables
#

my @records;
my @locString;
my @locNum;
my @locProv;

my $cityName;

my $province;
my $locAmount = 1;

my $provCount = -1;
my @locCity;
my $city;
my $outputLocation;
my $counter = 0;
$locCity[0] = 0;
my $i = 0;

###

my $SEP = q{,};
my $file = $ARGV[0];
my $qType = 0;
my $sYear = 0;
my $eYear = 0;
my $input;
my $outputStr;
my $location = "";
my $geoCount = 0;
my $locFile = "data/locs.data";
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
#START LOCATION
#
#opens location file and saves it to arrays
open my $locations_fh, '<', $locFile
or die "Error opening file\n";

@records = <$locations_fh>;
close $locations_fh;

foreach my $locationRecord (@records) {
    if ($csv->parse($locationRecord)) { #stores cities and coresponding numbers
        my @masterFields = $csv->fields();

        $locString[$i]   = $masterFields[0];
        $locNum[$i]      = $masterFields[1];
        $i++;
    } else {     #else statement stores provinces, with their represented number as a negtive
        if (index(@records, $SEP) == -1) {
            my @masterFields = $csv->fields();
            chomp $records[$i];
            $records[$i] = substr($records[$i], 1, length($records[$i])-2);
            chop $records[$i];
            chop $records[$i];
            $locString[$i]   = $records[$i];
            $locNum[$i]      = $provCount;
            $counter = $i -1;
            while ($locNum[$counter] < 0 && $counter >= 0) {
                $counter--;
            }
            $locCity[$provCount * (-1)-1] = $locNum[$counter];
            $provCount--;
            $i++;

        }
    }
}
#first and last cities messed up, this is temporarly hardcoded to fix it
$locCity[0] = 0;
$locCity[13] = 32;
$counter = 1;

#saves the stored provinces and cities into a hash rather than array
my %hash;
@hash{@locNum} = @locString;

#prints provinces and takes in answer
print "Please enter the province number\n";
print "0. All\n";
my $k = 1;
for (my $j = 0; $j < $i; $j++) {
    if ($locNum[$j] < 0) {
        print "$k. ";
        print $locString[$j];
        print "\n";
        $k++;
    }
}
chomp($province = <>);
while ($province < 0 || $province > (13)) {
    print "Invalid entry. Try again: ";
    chomp($province = <>);
}

#takes in city based on chosen province
if ($province != 0) {
    print "Please enter a city of $hash{-$province}\n";
    print "0. All\n";
    for (my $j = $locCity[$province-1]; $j < $locCity[$province]; $j++) {
        if ($j == 0) {
            print $counter.". ".$hash{$j};
            $counter++;
            print "\n";
        }
        print "$j. $hash{$j+1}";
        print "\n";
        $counter++;
    }
    chomp($city = <>);
    print $locCity[$province-1]."\n".$locCity[$province]."\n";
    while (($city < $locCity[$province-1] || $city >= $locCity[$province]) && $city != 0) {
        print "Invalid entry. Try again: ";
        chomp($city = <>);
    }
}

#formats the answer in order to be sent to output file
if ($province == 0) {
    $outputLocation = "\"Canada\"";
}
elsif ($city == 0) {
    $outputLocation = "\"$hash{-$province}\"";
} else {
    $outputLocation = "\"$hash{-$province},$hash{$city+1}\"";
}
print $outputLocation."\n";

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
