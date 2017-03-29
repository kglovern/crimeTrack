#/usr/bin/bash

#
# crimeTrack data parser - wrapper script
# Team Sarnia - Quinton Di Paolo, Jackson Firth, Kevin Glover-Netherton, Mitch Haflidson
#

# Make PDF Directory to store output if it doesn't exist
[ ! -d "OUTPUT" ] && mkdir OUTPUT
# Make Question directory to store past queries
[ ! -d "INPUT" ] && mkdir INPUT

#Make an output pdf file name
NOW=$(date +'%H%M%S')
OUTFILE="OUTPUT/output-$NOW.pdf"
INFILE="INPUT/input-$NOW"

# Run the user interface to generate the question query
perl uInterface.pl $INFILE
if [ -f INFILE ] then
    echo "Generating query results"
    # Generate data requested by the query
    perl query.pl $INFILE
    # Generate a pdf output
    clear
    perl plotData.pl output.data $OUTFILE
    clear
    echo "Answer PDF located at $OUTFILE"
fi
