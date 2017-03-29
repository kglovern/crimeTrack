#/usr/bin/bash

#
# crimeTrack data parser - wrapper script
# Team Sarnia - Quinton Di Paolo, Jackson Firth, Kevin Glover-Netherton, Mitch Haflidson
#

# Make PDF Directory to store output if it doesn't exist
[ ! -d "PDF" ] && mkdir PDF
# Make Question directory to store past queries
[ ! -d "QUERY"] && mkdir QUERY

#Make an output pdf file name
NOW=$(date +'%H%M%S')
OUTFILE="PDF/output-$NOW.pdf"
INFILE="QUERY/input-$NOW.pdf"

# Run the user interface to generate the question query
perl uInterface.pl $INFILE
# Generate data requested by the query
perl query.pl $INFILE
# Generate a pdf output
clear
perl plotCrime.pl output.data $OUTFILE
echo "Answer PDF located at $OUTFILE"
