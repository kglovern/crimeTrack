#!/usr/bin/bash

echo "This following script shows what happens if a query is run with invalid year ranges"
read -rsp "Press enter to continue"
perl ../query.pl  d1.query
echo "As shown, years outside the range give a warning, but are omitted from the query results"
read -rsp "Press enter to continue"
cat ../output.data
