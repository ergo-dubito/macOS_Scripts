#!/bin/bash

##########################################################################################
#  																				                                               #
#  				This script is to remove leaver accounts               				                 #
#																				                                                 #
# Created by : Suleyman Twana													                                   #
# Version: 1.0																	                                         #
# Date: 03/07/2017																                                       #
#																				                                                 #
##########################################################################################


#TempFile="/tmp/Leavers.txt"
LeaverHomeFolder=$(find /Users -iname \*Leaver-\* -type d -maxdepth 1)

# Warn that leaver accounts exist and will be removed

function LeaverFolderExists() {

  osascript <<EOT

set theAlertText to "Warning!"
set theAlertMessage to "You're about to remove leaver's home folder and account from this Mac. Would you like to continue?"
display alert theAlertText message theAlertMessage as critical buttons {"Don't Continue", "Continue"} cancel button "Don't Continue" default button "Continue"

EOT

}

# Warn that no leaver accounts exist

function NoLeaverFolderExists() {

  osascript <<EOT

set theAlertText to "Warning!"
set theAlertMessage to "No leaver's home folders found!"
display alert theAlertText message theAlertMessage as critical buttons {"OK"} default button "OK"
--> Result: {button returned:"OK"}
EOT

}

#########################################################
#                                                       #
#           Script starts from here                     #
#                                                       #
#########################################################

# Check if leaver accounts present on the Mac and if YES start the deletion process

	if [[ $LeaverHomeFolder == "" ]]; then

NoLeaverFolderExists

else

	if [[ $LeaverHomeFolder != "" ]]; then

	find /Users -iname \*Leaver-\* -type d -maxdepth 1 | sed 's/Users//;s/\///g' | sed 's/Leaver-//g' > /tmp/Leavers.txt

	LeaverFolderExists

	if [[ "$?" != "0" ]]; then

		echo "Nothing deleted"

else

	rm -r /Users/Leaver-*

# Now remove the DSCL records

while read -r line || [[ -n "$line" ]]; do

		echo "$line"

	dscl . -delete "/Users/$line"

done < /tmp/Leavers.txt

	rm -r /tmp/Leavers.txt

		fi

	fi

fi

exit 0
