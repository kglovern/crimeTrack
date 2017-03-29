#!/usr/bin/perl

#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');
use Text::CSV  1.32;

#
#  Variables
#
my $COMMA = q{,};
my $EMPTY = q{};
my $dataLoc = q{data/};
my $csv = Text::CSV->new({ binary=> 1, sep_char => $COMMA });
my $crimeStatsFile;
my $fh;
my $outputStr;
my $cityID = 0;
my $vioID = 0;
# Arrays
my @records;
my @relevantFields;
# Hashes
my %crimeData;
my %locations;
my %violations;

#
# Check for correct # of args - CHANGE THIS AS WE ADD FILES TO PARSE
#
if ($#ARGV != 0) {
   print "Usage: murderRate.pl <crime data file>\n";
   exit;
} else {
   $crimeStatsFile = $ARGV[0];
}

#
# Attempt to open and parse the crime stats file
#
print "Provided crime stats file: $crimeStatsFile\n";

open $fh, '<', $crimeStatsFile
   or die "Unable to open $crimeStatsFile\n";

@records = <$fh>;

close $fh;

shift @records; #Get rid of header info - we don't need to store that

foreach my $rec ( @records ) {
   if ( $csv->parse($rec) ) {
      my @fields = $csv->fields();
      $crimeData{$fields[0]}{$fields[1]}{$fields[2]}{$fields[3]} = $fields[6];
      # Violation parsing
      $violations{$fields[2]} = 0;
      # Location parsing
      my $loc =  $fields[1];
      if ($loc =~ /^[a-z\s]*$/i) {
         if (not exists $locations{$loc} and $loc ne "Canada") {
            $locations{$loc} = {};
         }
      } else {
         my @parts = split (", ", $loc);
         my $city = $parts[0];
         my $province = $parts[1];
         if (not $province =~ / +part$/) { #Gatineau/Ottawa split
            $locations{$province}{$city} = $cityID;
         } else {
            if ($province =~ /^Ontario/) { #shunt them into appropriate province
               $locations{"Ontario"}{$city} = $cityID;
            } else {
               $locations{"Quebec"}{$city} = $cityID;
            }
         }
      }

   } else {
      warn "Could not parse: $rec\n";
   }
}

#
# Output the data into a new file format
#

# What statistic fields we want
@relevantFields = ("Actual incidents",
                   "Rate per 100,000 population",
                   "Total, adult charged",
                   "Total, youth charged");

while (my ($year, $locs) = each %crimeData) {
   my $yearFile = $dataLoc.$year."Crime.csv";

   print "Outputting: $yearFile\n";

   open $fh, ">:encoding(utf8)", $yearFile
      or die "Unable to open $yearFile for writing";

   print $fh "\"Geo\",\"Vio\",\"Actual incidents\",\"Rate Per 100,000\",\"Adults charged\",\"Youth charged\"\n";
   while (my ($loc, $violations) = each %$locs) {
      while (my ($violation, $stats) = each %$violations) {

         $outputStr = "\"$loc\"".$COMMA."\"$violation\"";

         foreach my $field ( @relevantFields ) {
            if (exists $stats->{$field}) {
               my $value = ($stats->{$field} eq "..") ? 0 : $stats->{$field};
               $outputStr = $outputStr.$COMMA.$value;
            } else {
               $outputStr = $outputStr.$COMMA."0";
            }
         }
         print $fh $outputStr."\n"; # Print the line to the current file
      }
   }
   close $fh
}

#
# Output the location data
#

print "\nOutputting formatted location data\nFile located at $dataLoc"."locs.data";

open $fh, ">:encoding(utf8)", $dataLoc."locs.data";
while (my ($province, $cities) = each %locations) {
   if (not $province =~ /^Ontario\/Quebec$/) {
      print $fh "\"$province\"\n";
      while (my ($city, $id) = each %$cities) {
         print $fh "\"$city\",$cityID\n";
         $cityID ++;
      }
   }
}
close $fh;

print "\nOutputting formatted violation data\n";

open $fh, ">:encoding(utf8)", $dataLoc."vios.data";
while (my ($violation, $id) = each %violations) {
    print $fh "\"$violation\",$vioID\n";
    $vioID ++;
}
close $fh;
