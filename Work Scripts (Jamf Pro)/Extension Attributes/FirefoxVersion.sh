#!/bin/bash

########################################################################
############## Check Current Mozilla Firefox Version ###################
############### written by Phil Walker October 2017 ####################
########################################################################

RESULT="Not Installed"

if [ -d "/Applications/Firefox.app" ] ; then
	RESULT=$( /usr/bin/defaults read /Applications/Firefox.app/Contents/Info.plist CFBundleShortVersionString )
fi
echo "<result>$RESULT</result>"
