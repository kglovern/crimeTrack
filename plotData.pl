#!/usr/bin/perl
#
#   Packages and modules
#
use strict;
use warnings;
use version;         our $VERSION = qv('5.16.0');   # This is the version of Perl to be used
use Statistics::R;

my $infilename;
my $pdffilename;
my $qType;

#
#   Check that you have the right number of parameters
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

open my $fh, "<", $infilename;
$qType = <$fh>;
close $fh;

# Create a communication bridge with R and start R
my $R = Statistics::R->new();

# Name the PDF output file for the plot  
#my $Rplots_file = "./Rplots_file.pdf";

# Set up the PDF file for plots
$R->run(qq`pdf("$pdffilename" , paper="letter")`);

# Load the plotting library
$R->run(q`library(ggplot2)`);

# read in data from a CSV file
$R->run(qq`data <- read.csv("$infilename", skip = 1)`);

# plot the data as a line plot with each point outlined
$R->run(q`ggplot(data, aes(x=Year, y=RP1K, colour=Vio, group=Vio)) + geom_line() + geom_point(size=2) + geom_text(aes(label=RP1K),hjust=0, nudge_x=0.25, vjust=0, nudge_y=0.25, angle = 45, size=3) + ggtitle("Crime Trends") + ylab("Rate per 100,000 population") + labs(fill = "Violation") + ylim(min(data$RP1K), max(data$RP1K)) + xlim(min(data$Year), max(data$Year)) + scale_y_continuous(breaks=seq(min(data$RP1K), max(data$RP1K), 1)) + scale_x_continuous(breaks=seq(min(data$Year), max(data$Year), 1)) + theme(axis.text.x = element_text(angle = 45, hjust = 1))`);
# close down the PDF device
$R->run(q`dev.off()`);

$R->stop();
