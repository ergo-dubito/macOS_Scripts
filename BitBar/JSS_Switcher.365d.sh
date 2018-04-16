#!/bin/bash

#Get the current JSS url from the JAMf plist and add to a variable
jssURL=$(defaults read /Users/philwalker/Library/Preferences/com.jamfsoftware.jss.plist url)
#Check which URL is configured and set the name that appears in the menu bar
if [[ $jssURL == "https://casper.bauerservices.co.uk:443/" ]] || [[ $jssURL == "https://casper.bauerservices.co.uk/" ]] ; then
	echo "Prod JSS | color=blue"
fi
if [[ $jssURL == "https://caspertest.bauerservices.co.uk:443/" ]] || [[ $jssURL == "https://caspertest.bauerservices.co.uk/" ]] ; then
	echo "Test JSS | color=red"
fi

#Start the sub menu
echo "---"
echo "Production | bash="/Users/philwalker/Documents/PackagingStuff/jssswitcher/prodjss.sh" terminal=false refresh=true" color=blue
echo "Test | bash="/Users/philwalker/Documents/PackagingStuff/jssswitcher/testjss.sh" terminal=false refresh=true" color=red

exit 0
