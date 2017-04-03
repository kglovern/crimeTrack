#!/usr/bin/perl
#
#   Packages and modules
#
use strict;
use warnings;
use version;         our $VERSION = qv('5.16.0');   # This is the version of Perl to be used
use Statistics::R;
use Text::CSV  1.32;   # I will be using the CSV module (version 1.32 or higher)
                       # to parse the question
#
#  plotCrime.pl
#      Author: Jackson Firth (0880887)
#      Project: Team Assignment CIS2250 W17, Crime Stats Project
#      Date of Last Update: Thursday March 30, 2017
#
#      Functional Summary
#          plotCrime.pl takes as input a file containing data generated from the perl script query.pl
#          regarding specific criteria outlining a question regarding crime in Canada. These criteria are
#          gathered from the perl script uInterface.pl. The second input is the name of the pdf file you
#          want the plot written to.
#          The first line of the input file is then parsed to determine the question that was asked.
#          A communication bridge is the opened with R and the pdf file that was inputted is set up for a
#          plot. The plotting libraries are then loaded, after which the data is read from the input file
#          into a data table in R. The structure containing the question type is then compared to
#          determine what kind of graph is to be outputted. Once the proper graph has been outputted, the
#          pdf device is then closed down and the communication bridge with R is stopped.
#
#      Commandline Parameters: 2
#          $ARGV[0] = name of input file containing data to be plotted
#          $ARGV[1] = name of pdf file for the plot to be written to
#
#      References
#          Data gathered from: http://www5.statcan.gc.ca/cansim/a26?lang=eng&retrLang=eng&id=2520051&tabMode=dataTable&srchLan=-1&p1=-1&p2=9
#

#
#  Variables to be used
#
my $COMMA         = q{,};
my $csv           = Text::CSV->new({ sep_char => $COMMA });
my $infilename;
my $pdffilename;
my $question;
my $graphTitle;
my $Geos          ="";
my $Vios          ="";

my @fields;

#
#   Check that you have the right number of parameters (2)
#
if ($#ARGV != 1 ) {
   print "Usage: plotData.pl <input file name> <pdf file name>\n" or
      die "Print failure\n";
   exit;
} else {
   $infilename = $ARGV[0];
   $pdffilename = $ARGV[1];
}  

print "input file = $infilename\n";
print"pdf file = $pdffilename\n";

#
#   Parse into @fields, which has the following fields:
#
#   [0]: question type (1, 2, 3, 4)
#   [1]: start year
#   [2]: end year
#   [3]: number of GEOs
#   [4 to 4 + # of GEOs]: GEOs (up to fields[3] number of them)
#   [3 + number of GEOs]: Violation
#
open my $fh, "<", $infilename;
$question = <$fh>;
if ( $csv->parse($question) ) {
    @fields = $csv->fields();
} else {
    warn "Question could not be parsed.\n";
}
close $fh;

for my $i (4..(3 + $fields[3])) {
    $Geos = $Geos.$fields[$i].$COMMA;
}
for my $j ((4 + $fields[3])..$#fields) {
    $Vios = $Vios.$fields[$j].$COMMA;
}

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

# Name the PDF output file for the plot  
#my $Rplots_file = "./Rplots_file.pdf";

# Set up the PDF file for plots
$R->run(qq`pdf("$pdffilename" , paper="letter")`);

# Load the plotting libraries
$R->run(q`library(ggplot2)`);
$R->run(q`library(plyr)`);
#$R->run(q`library(grid)`);
#$R->run(q`library(lattice)`);

# read in data from a CSV file
$R->run(qq`data <- read.csv("$infilename", skip = 1)`);

if ($fields[0] == 1) {
    $graphTitle = "Actual Incidents, ".$fields[1]." - ".$fields[2];
    $R->run(qq`ggplot(data, aes(x=Year, y=Value, group=Vio, colour=Vio)) + geom_line() +
    geom_point(size=1) + facet_grid(Geo~.) +
    ggtitle("$graphTitle") + ylab("Actual Incidents") + labs(fill = "Violation") +
    scale_x_continuous(breaks=seq(min(data\$Year), max(data\$Year), 1)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) + stat_smooth(method = "lm", se = FALSE)`);
} elsif ($fields[0] == 2) {
    #$Geos =~ tr/,//d;
    $graphTitle = $Geos." Incident Rate ".$fields[1]." - ".$fields[2];
    $R->run(qq`ggplot(data, aes(x=Year, y=Value, colour=Vio, group=Vio)) + geom_line() +
    geom_point(size=1) +
    ggtitle("$graphTitle") + ylab("Rate per 100,000 population") +
    ylim(min(data\$Value), max(data\$Value)) + xlim(min(data\$Year), max(data\$Year)) +
    scale_x_continuous(breaks=seq(min(data\$Year), max(data\$Year), 1)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) + stat_smooth(method = "lm", se = FALSE)`);
} elsif ($fields[0] == 3) {
    $Vios =~ tr/,//d;
    $graphTitle = $Vios."\nIncident Rate vs National Average\n".$fields[1]." - ".$fields[2];
    $R->run(qq`ggplot(data, aes(x=Year, y=Value, colour=Geo, group=Geo)) + geom_line() +
    geom_point(size=1) + ggtitle("$graphTitle") + ylab("Rate per 100,000 population") +
    ylim(min(data\$Value), max(data\$Value)) + xlim(min(data\$Year), max(data\$Year)) +
    scale_x_continuous(breaks=seq(min(data\$Year), max(data\$Year), 1)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))`);
} elsif ($fields[0] == 4) {
    $graphTitle = "Incident Rate for the Nation ".$fields[1]." - ".$fields[2];
    $R->run(qq`ggplot(data, aes(x=Year, y=Value, group=Vio, colour=Vio)) + geom_line() +
              geom_point(size=1) + facet_grid(Geo~.) + ylab("Rate per 100,000 population") +
              scale_x_continuous(breaks=seq(min(data\$Year), max(data\$Year), 1)) +
              theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
              ggtitle("$graphTitle")`);
}

# close down the PDF device
$R->run(q`dev.off()`);

$R->stop();
