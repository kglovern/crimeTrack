#!/bin/bash

echo "Scenario: Where not to move?"
read -rsp "Press enter to continue"
echo ""
echo "Our input for the following question is as follows:"
echo ""
cat demo/d4.que
echo ""
read -rsp "Press enter to continue to generating output"
perl query.pl  demo/d4.que
perl plotCrime.pl output.data demo/d4.pdf
read -rsp "Press enter to display the graph"
open demo/d4.pdf
