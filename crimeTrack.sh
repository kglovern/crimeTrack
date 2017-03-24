#/usr/bin/bash

#
# crimeTrack data parser - wrapper script
# Team Sarnia - Quinton Di Paolo, Jackson Firth, Kevin Glover-Netherton, Mitch Haflidson
#

#Make an output pdf file name
NOW=$(date +'%H%M%S')
OUTFILE="output-$NOW.pdf"

# Run the user interface to generate the question query
perl ui.pl
# Generate data requested by the query
perl query.pl input.que
# Generate a pdf output
clear
perl plotCrime.pl output.data $OUTFILE
echo "Answer PDF located at $OUTFILE"
