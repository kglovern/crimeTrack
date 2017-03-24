#!/usr/bin/perl

# TODO:
#  - Any and all error checking
#  - Year range sanitation - currently dies if file doesn't exist
#  - Are we using a second data set?  How to include?

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
my $dataDir = "./data/";
my $fh;
my $queryFile;
my $crimeDataFile;
my $startYear;
my $endYear;
my $questionType;
my $geoCount;
my $geoStart = 4;
my $csv = Text::CSV->new ({ binary=> 1, sep_char => $COMMA});
#   Arrays
my @years = ();
my @queries;
my @records;
my @geos = ();
my @vios = ();
#   Hashes
my %data;

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

        # We know these fields are consistent between question types/queries.
        $questionType = $fields[0];
        $startYear = $fields[1];
        $endYear = $fields[2];
        $geoCount = $fields[3];

        # Push N geos into the array - using the $geoCount offset to know when geos stop
        for (my $i  = $geoStart; $i < ($geoStart + $geoCount); $i++) {
           push @geos, $fields[$i];
        }
        #push N violations into the Arrays - from offset to end of line
        for (my $i = $geoStart + $geoCount; $i <= $#fields; $i ++) {
           push @vios, $fields[$i];
        }
    } else {
        exit;
    }
}

print "\nRetrieving query data from $startYear to $endYear\n";

#
# Generate list of years to look at
# TODO: Error checking range - make sure we have at least start year
while ($startYear <= $endYear) {
    push @years, $startYear;
    $startYear ++;
}

#
# Load that data in
#
foreach my $year ( @years ) {
   $crimeDataFile = $dataDir.$year."Crime.csv";
   print "Parsing $crimeDataFile\n";

   open $fh, "<", $crimeDataFile
      or die "Unable to open data file $crimeDataFile\n";

   @records = <$fh>;
   shift @records; #Get rid of header line
   close $fh;

   foreach my $record ( @records ) {
      if ($csv->parse($record)) {
         my @fields = $csv->fields();
         $data{$year}{$fields[0]}{$fields[1]} = $fields[3];
      } else {
         warn "Couldn't parse record line\n";
      }
   }
}

#
# Output to new file
#

open $fh, ">:encoding(utf8)", "output.data"
   or die "Unable to open file for outputting";

print $fh "$questionType,$startYear,$endYear\n";
print $fh "\"Year\",\"Geo\",\"Vio\",\"RP1K\"\n";
foreach my $geo ( @geos ) {
   foreach my $vio ( @vios ) {
      foreach my $year ( @years ) {
         my $RP1K = 0.00;
         if (exists $data{$year}{$geo}{$vio}) {
            $RP1K = $data{$year}{$geo}->{$vio};
         }
         print $fh $year.$COMMA."\"$geo\"".$COMMA."\"$vio\"".$COMMA.$RP1K."\n"
            or die "Unable to output line to file\n";
      }
   }
}
close $fh;
