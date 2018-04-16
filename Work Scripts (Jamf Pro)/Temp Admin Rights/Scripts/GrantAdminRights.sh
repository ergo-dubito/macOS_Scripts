#!/bin/bash

#######################################################################
################ Grant Logged In User Admin Rights ####################
############### Created by Phil Walker August 2017 ####################
#######################################################################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

#Add the logged in user to the admin group
dseditgroup -o edit -a "$LoggedInUser" -t user admin

#Load and Start the LaunchDaemon
launchctl load /Library/LaunchDaemons/com.bauer.tempadmin.plist
launchctl start /Library/LaunchDaemons/com.bauer.tempadmin.plist

exit 0
