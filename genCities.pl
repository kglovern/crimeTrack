#!/usr/bin/perl

#
#   Packages and modules
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');
use Text::CSV  1.32;


my $fh;
my $csv = Text::CSV->new({ binary => 1});
my @records;
my @cities;
my %provinces;
my $cityCount = 0;

open $fh, "<", "./data/2015Crime.csv"
   or die "Unable to open file";

<$fh>; #Get rid of header line - don't want the column headers

while (my $record = <$fh>) {
   $csv->parse($record);
   my @fields = $csv->fields;
   my $loc = $fields[0];
   if ($loc =~ /^[a-z\s]*$/i) {
      print "$loc is a province\n";
      if (not exists $provinces{$loc} and $loc ne "Canada") {
         $provinces{$loc} = {};
      }
   } else {
      my @parts = split (", ", $loc);
      my $city = $parts[0];
      my $province = $parts[1];
      print "$city is the city, $province is the province\n";
   }
}

while (my ($province, $cities) = each %provinces) {
   print "$province\n";
}

close $fh;
