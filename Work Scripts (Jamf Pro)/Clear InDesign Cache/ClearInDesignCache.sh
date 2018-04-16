#!/bin/bash

######################################################################
########### Clear InDesign cache for the logged in user ##############
############### Written by Phil Walker Feb 2018 ######################
######################################################################

#########################
####### Variables #######
#########################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"

#Check InDesign is installed
adobeInDesign=$(ls /Applications/ | grep -i "InDesign" 2>/dev/null)

#########################
###### Functions ########
#########################

#JamfHelper message asking the user to close InDesign
function jamfHelper_CloseInDesign ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Adobe\ InDesign\ CS6/Adobe\ InDesign\ CS6.app/Contents/Resources/ID_App_Icon.icns -title "Message from Bauer IT" -heading "Clear Adobe InDesign Cache" -description "Please save all of your work in InDesign and then select the continue button to close the app.

Once closed the cache will be cleared.

❗️All unsaved changes to InDesign documents will be lost (Recovery data, clipboard data etc)" -button1 "Continue" -button2 "Cancel" -defaultButton 1 -cancelButton 2
}

#JamfHelper message to confirm the cache has been deleted
function jamfHelper_InDesignCacheCleared ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Adobe\ InDesign\ CS6/Adobe\ InDesign\ CS6.app/Contents/Resources/ID_App_Icon.icns -title "Message from Bauer IT" -heading "InDesign Cache Cleared" -description "InDesign's cache has now been cleared." -button1 "Ok" -defaultButton 1
}

#JamfHelper message to advise that they have cancelled the request
function jamfHelper_Cancelled ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Adobe\ InDesign\ CS6/Adobe\ InDesign\ CS6.app/Contents/Resources/ID_App_Icon.icns -title "Message from Bauer IT" -heading "InDesign Cache Not Cleared" -description "Request cancelled.

Nothing has been deleted." -button1 "Ok" -defaultButton 1
}

#Delete both Adobe InDesign directories from ~/Library/Caches
function clearInDesignCache() {
if [[ -d "/Users/$LoggedInUser/Library/Caches/Adobe InDesign" ]]; then
	rm -rf "/Users/$LoggedInUser/Library/Caches/Adobe InDesign"
	rm -rf "/Users/$LoggedInUser/Library/Caches/com.adobe.InDesign" 2>/dev/null
else
	echo "InDesign cache directories not found - Nothing to clear"
	jamfHelper_InDesignCacheCleared
	exit 0
fi

}

#Check InDesign cache has been cleared successfully
function checkCacheCleared() {
if [[ ! -d "/Users/$LoggedInUser/Library/Caches/Adobe InDesign" ]]; then
	echo "InDesign cache cleared"
else
	echo "Cache not cleared"
	exit 1
fi
}

#Check if InDesign is running, if it is then ask the user to save work as it will be closed once Continue is clicked.
#Once closed InDesign cache will be cleared for current user
function closeInDesign() {

#### Variables #####
PIDName=`ps -ef | grep InDesign | grep -v grep | awk '{ print $11 }' | head -n 1`
PIDNumber=`ps -ef | grep InDesign | grep -v grep | awk '{ print $2 }' | head -n 1`

jamfHelper_CloseInDesign 2>/dev/null
if [[ "$?" != "0" ]]; then
	echo "User selected Cancel, nothing will be deleted"
		jamfHelper_Cancelled
		exit 1
fi

if [[ "$?" == "0" ]]; then
	if [[ $PIDName != InDesign ]]; then
		echo "InDesign not open - clearing cache"

			#Clear InDesign Cache
			clearInDesignCache
			sleep 3

				#Check cache has been cleared successfully
				checkCacheCleared
				jamfHelper_InDesignCacheCleared
				exit 0
				sleep 5
else
	kill $PIDNumber
		echo "InDesign process killed - clearing cache"

			#Clear InDesign Cache
			clearInDesignCache
			sleep 3

				#Check cache has been cleared successfully
				checkCacheCleared
				jamfHelper_InDesignCacheCleared
				exit 0
				sleep 5
	fi
fi

}

##########################
### script starts here ###
##########################

if [ "${adobeInDesign}" == "" ]; then
  echo "Adobe InDesign is not installed - Nothing to clear"
  exit 1
else
  echo "Adobe InDesign installed, continuing..."
closeInDesign
fi

exit 0
