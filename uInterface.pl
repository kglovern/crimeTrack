#!/usr/bin/perl

use strict;
use warnings;
use version;	our $VERSION = qv('5.16.0');
use Text::CSV 1.32;

#variable declaration
my $file = "outputfile.txt";
my $COMMA = q{,};
my @records;
my @locString;
my @locNum;
my @locProv;
my $locFile = "locs.data";
my $cityName;
my $qType = 0;
my $sYear = 0;
my $eYear = 0;
my $province;
my $locAmount = 1;
my $crimeAType = 0;
my $crimeBType = 0;
my $provCount = -1;
my @locCity;
my $city;
my $outputLocation;
my $counter = 0;
$locCity[0] = 0;
my $i = 0;
my $csv		= Text::CSV->new ({binary=> 1,sep_char => $COMMA });


#opens the output file to write to
open (my $fh, ">", $file)
    or die "error, file broken";

#takes in question type
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

#takes the start and end year
print "Please enter the start year.\n";
chomp($sYear = <>);
while ($sYear < 1998 || $sYear > 2015) {
    print "Sorry, we do not have data for that year, try again.\n";
    chomp($sYear = <>);
}
# $input =~ /[\d]{4}/

print "Please enter the end year.\n";
chomp($eYear = <>);
if ($eYear < $sYear) {
    $eYear = $sYear;
}
while ($eYear > 2015) {
    print "Sorry, we do not have data for that year, try again.\n";
    chomp($eYear = <>);
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
        if (index(@records, $COMMA) == -1) {
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
#takes crime data (kevin doing this)
#
print "Please enter a keyword for crime A, all possible crimes will be displayed.\n";
chomp($crimeAType = <>);
#foreach my $crime (@crimeTypes) {
#    if (index(lc($crimeTypes[$i]), lc($crimeAType)) != -1) {
#        print "$crime\n";
#    }
#} 

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


#output to the file

if ($qType == 4) {
print $fh $qType.",".$sYear.",".$eYear.",".$locAmount.",".$outputLocation.",\"".$crimeAType."\",\"".$crimeBType."\"";
}
else {
print $fh $qType.",".$sYear.",".$eYear.",".$locAmount.",".$outputLocation.",\"".$crimeAType."\"";
} 

close $fh;
