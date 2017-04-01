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
my @newGroup;
my %provinces;
my %groups;
my $cityCount = 0;

sub removeRep {
  my %rep;
  grep !$rep{$_}++, @_;
}

open $fh, "<", "./data/2015Crime.csv"
   or die "Unable to open file";

<$fh>; #Get rid of header line - don't want the column headers

while (my $record = <$fh>) {
   $csv->parse($record);
   my @fields = $csv->fields;
   my $loc = $fields[0];
   if ($loc =~ /^[a-z\s]*$/i) {
      #print "$loc is a province\n";
      if (not exists $provinces{$loc} and $loc ne "Canada") {
         $provinces{$loc} = {};
      }
   } else {
      my ($city, $province) = split (", ", $loc);
      push(@{$groups{$province}}, $city);
   }
}
foreach my $group (keys %groups) {
   print "$group\n";
   @newGroup = removeRep(@{$groups{$group}});
   foreach my $element (@newGroup) {
     my ($index) = grep {$newGroup[$_] ~~ $element} 0..$#newGroup;
     print "\t$element, $index\n";
   }
}
while (my ($province, $cities) = each %provinces) {
   #print "$province\n";
}

close $fh;

