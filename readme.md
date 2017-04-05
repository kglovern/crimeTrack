# Team Sarnia - Crime Statistics Application
The following is our Crime Statistics answer generator for CIS*2250 Winter 2017.

It looks at crime statistics and other census data from Stats Canada/Canada census and attempts to answer questions posed to it by the user.

Answers to the query will be outputted in a PDF graph format

# Team Members
- Quinton Di Paolo
- Jackson Firth
- Kevin Glover-Netherton
- Mitchell Haflidson

# Instructions
 - If the data directory does not exist, run the parseData script using the crime data file location as a command line argument
 - Alternatively, if the data directory does not exist, running crimeTrack.sh will prompt you for the location of the crime data CSV to aggregate the information
 - Run the program using the crimeTrack.sh script and follow the one screen prompts
 - Output PDF location should be indicated to the user at the completion of the script

# Known Issues/workarounds
- User must have read/write permissions for the working directory
- Inputting a start year that is less than the end year will intentionally result in a data range consisting only of the start year
-
