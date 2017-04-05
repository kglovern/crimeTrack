#!/bin/bash

echo "Scenario: 'Tough' on crime?'"
read -rsp "Press enter to continue"
echo ""
echo "Our input for the following question is as follows:"
echo ""
cat demo/d3.que
echo ""
read -rsp "Press enter to continue to generating output"
perl query.pl  demo/d3.que
perl plotCrime.pl output.data demo/d3.pdf
read -rsp "Press enter to display the graph"
open demo/d3.pdf
