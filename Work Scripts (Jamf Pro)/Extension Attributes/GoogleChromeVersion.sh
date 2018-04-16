#!/bin/bash

########################################################################
############### Check Current Google Chrome Version ####################
############### written by Phil Walker October 2017 ####################
########################################################################

RESULT="Not Installed"

if [ -d /Applications/Google\ Chrome.app ] ; then
	RESULT=$( /usr/bin/defaults read "/Applications/Google Chrome.app/Contents/Info.plist" CFBundleShortVersionString )
fi
echo "<result>$RESULT</result>"
