#!/bin/bash

#The below runs to make sure that the tempadmin launchD is not loaded and deletes the plist

launchctl stop /Library/LaunchDaemons/com.bauer.tempadmin.plist 2>/dev/null

launchctl unload /Library/LaunchDaemons/com.bauer.tempadmin.plist 2>/dev/null

if [ -f /Library/LaunchDaemons/com.bauer.tempadmin.plist ]; then

  rm -f /Library/LaunchDaemons/com.bauer.tempadmin.plist

fi

if [ ! -f /Library/LaunchDaemons/com.bauer.tempadmin.plist ]; then
  echo "Temp Admin LaunchDaemon stopped, unloaded and deleted"

  exit 0

else

  echo "Somthing went wrong - temporary admin rights cannot be provided"
  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "Administrator Priviliges failed" -description "It looks like something went wrong when trying to change your account priviliges.

  Please contact the IT Service Desk for assistance" -button1 "Ok" -defaultButton 1

exit 1
fi
