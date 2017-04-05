#!/bin/bash

echo "Scenario: War on Drugs in Quebec"
read -rsp "Press enter to continue"
echo ""
echo "Our query input for this scenario looks like the following:"
echo ""
cat demo/d2.que
echo ""
read -rsp "Press enter to continue to generating output"
perl query.pl  demo/d2.que
perl plotCrime.pl output.data demo/d2.pdf
open demo/d2.pdf
