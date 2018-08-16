#!/bin/bash

########################################################################
#################### Variables to pulled in from policy ################
########################################################################

#PolicyTrigger="$4" #What unique policy trigger actually installs the package
#deferralOption1="$5" #deferral time option 1 e.g 0, 300, 3600, 21600 (Now, 5 minutes, 1 hour, 6 hours)
#deferralOption2="$6" #deferral time option 2 e.g 0, 300, 3600, 21600 (Now, 5 minutes, 1 hour, 6 hours)
#deferralOption3="$7" #deferral time option 3 e.g 0, 300, 3600, 21600 (Now, 5 minutes, 1 hour, 6 hours)
#deferralOption4="$8" #deferral time option 4 e.g 0, 300, 3600, 21600 (Now, 5 minutes, 1 hour, 6 hours)


#DEBUG
deferralOption1="600"
deferralOption2="3600"
deferralOption3="10800"
deferralOption4="21600"

########################################################################
#                            Variables                                 #
########################################################################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
#Get the hostname
hostName=`scutil --get HostName`
#Get the logged in user's real name
RealName=$(dscl . -read /Users/$LoggedInUser | grep -A1 "RealName:" | sed -n '2p' | awk '{print $2, $1}' | sed s/,//)

########################################################################
#                            Functions                                 #
########################################################################

jamfHelperAdminPeriod ()
#Prompt the user to select the time period they which to have admin rights for
{
HELPER=$(
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns -title "Message from Bauer IT" -heading "Admin Privileges Requested" -alignHeading left -description "Please select the time period you require admin privileges for

" -lockHUD -showDelayOptions "$deferralOption1, $deferralOption2, $deferralOption3, $deferralOption4"  -button1 "Select"

)
}

convertTimePeriod ()
{
#Convert the seconds chosen to human readable minutes, hours. No Seconds are calulated
local T=$timeChosen;
local H=$((T/60/60%24));
local M=$((T/60%60));
timeChosenHuman=$(printf '%s';[[ $H -eq 1 ]] && printf '%d hour' $H; [[ $H -ge 2 ]] && printf '%d hours' $H; [[ $M > 0 ]] && printf '%d minutes' $M; [[ $H > 0 || $M > 0 ]])

}

########################################################################
#                         Script starts here                           #
########################################################################

jamfHelperAdminPeriod
timeChosen="${HELPER%?}" #Removes the 1 added to the time period chosen
convertTimePeriod

#Promote the logged in user to an admin
dseditgroup -o edit -a "$LoggedInUser" -t user admin

#Add time period to LaunchDaemon
/usr/libexec/PlistBuddy -c "Set StartInterval $timeChosen" /Library/LaunchDaemons/com.bauer.tempadmin.plist

#Start the launchD to remove admin rights after the chosen period has elapsed
launchctl load /Library/LaunchDaemons/com.bauer.tempadmin.plist
launchctl start /Library/LaunchDaemons/com.bauer.tempadmin.plist

#Get a list of users who are in the admin group
adminUsers=$(dscl . -read Groups/admin GroupMembership | cut -c 18-)

#Check if the logged in user is in the admin group and show jamfHelper message
if [[ "$adminUsers" == *"$LoggedInUser" ]]; then
  echo "$LoggedInUser is now an admin"
  #Kill bitbar to read to hostname
  killall BitBarDistro

#Show jamfHelper message to advise admin rights given and how long the privileges will be in place for
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "🔓 Administrator Privileges Granted" -description "$RealName now has admin rights on $hostName for $timeChosenHuman

After $timeChosenHuman, admin privileges will be automatically removed and you will not be able to request them again for 24 hours.

During the $timeChosenHuman of elevated privileges please remember....

    #1) All activity on your Bauer Media owned Mac is monitored.
    #2) Think before you approve installs or updates
    #3) With great power comes great responsibility." -button1 "Ok" -defaultButton 1

exit 0

else
  echo "Somthing went wrong - $LoggedInUser is not an admin"
  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "Administrator Priviliges failed" -description "It looks like something went wrong when trying to change your account priviliges.

  Please contact the IT Service Desk for assistance" -button1 "Ok" -defaultButton 1

exit 1
fi
