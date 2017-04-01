#/usr/bin/bash

#
# crimeTrack data parser - wrapper script
# Team Sarnia - Quinton Di Paolo, Jackson Firth, Kevin Glover-Netherton, Mitch Haflidson
#

# Check if the data directory exists.  Run the aggregator if not
if [ ! -d data ]
   then
      mkdir data
      echo "Data directory does not exist"
      echo "Enter location of crime data csv for parsing:"
      read FILELOC
      [ -f FILELOC ] && perl parseData FILELOC
fi

[ ! -d data ] && exit -1

# Make PDF Directory to store output if it doesn't exist
[ ! -d "OUTPUT" ] && mkdir OUTPUT
# Make Question directory to store past queries
[ ! -d "INPUT" ] && mkdir INPUT

#Make an output pdf file name
NOW=$(date +'%H%M%S')
OUTFILE="OUTPUT/output-$NOW.pdf"
INFILE="INPUT/input-$NOW.que"

# Run the user interface to generate the question query
perl uInterface.pl $INFILE
if [ -f $INFILE ]
   then
      echo "Generating query results"
      # Generate data requested by the query
      perl query.pl $INFILE
      # Generate a pdf output
      clear
      perl plotCrime.pl output.data $OUTFILE
      clear
      echo "Answer PDF located at $OUTFILE"
fi
