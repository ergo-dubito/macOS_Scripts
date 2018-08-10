#!/bin/bash

#################
### Variables ###
#################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
#Get the hostname
hostName=`scutil --get HostName`
#Get the logged in user's real name
RealName=$(dscl . -read /Users/$LoggedInUser | grep -A1 "RealName:" | sed -n '2p' | awk '{print $2, $1}' | sed s/,//)

#################
### Functions ###
#################

function getAdminTime1 ()
{
adminPeriod1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndAdminTime1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter how long you require admin rights - 10 mins 1/3/6 hours (Enter numeric values only)") with title ("Admin Rights Time Period") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndAdminTime1
)
echo "Admin Time Period Requested : $adminPeriod1"
}

function getAdminTime2 ()
{
adminPeriod2=$(su - $LoggedInUser -c /usr/bin/osascript <<EndAdminTime2
tell application "System Events"
    activate
    set the_results to (display dialog ("Please only enter one of the following values 10 / 1 / 3 or 6 (10 minutes / 1/3/6 Hours)") with title ("Admin Rights Time Period") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndAdminTime2
)
echo "Admin Time Period Requested : $adminPeriod2"
}

function checkValueEntered1() {
if [[ $adminPeriod1 -eq "10" ]]; then
  echo "minutes"
else
  echo "hours"
fi

}

function checkValueEntered2() {
if [[ $adminPeriod2 -eq "10" ]]; then
  echo "minutes"
else
  echo "hours"
fi
}

function checkEnteredPeriod() {
getAdminTime1

if [[ "$adminPeriod1" =~ [^[:digit:]] ]]; then
  echo "Period entered contains non digits and must be re-entered"
  getAdminTime2
  if [[ "$adminPeriod2" =~ [^[:digit:]] ]]; then
    echo "Period entered contains non digits again, jamfHelper will be displayed to ask that the policy is run again"
  else
    echo "Period entered contains only digits"
      if [[ "$adminPeriod2" -eq "10" ]] || [[ "$adminPeriod2" -eq "1" ]] || [[ "$adminPeriod2" -eq "3" ]] || [[ "$adminPeriod2" -eq "6" ]]; then
        echo "Period entered accepted"
      else
        echo "Period entered incorrect"
        echo "Your dont deserve admin rights!"
      fi
    fi
  fi
else
  echo "Period entered contains only digits"
    if [[ "$adminPeriod1" -eq "10" ]] || [[ "$adminPeriod1" -eq "1" ]] || [[ "$adminPeriod1" -eq "3" ]] || [[ "$adminPeriod1" -eq "6" ]]; then
      echo "Period entered accepted"
      checkValueEntered1
    else
      echo "Period entered incorrect"
      getAdminTime2
      checkValueEntered2
  fi
fi
}

checkEnteredPeriod

#Promote the logged in user to an admin
dseditgroup -o edit -a "$LoggedInUser" -t user admin

#Start the launchD to remove admin rights in 3600 seconds (1 hour)
launchctl load /Library/LaunchDaemons/com.bauer.tempadmin.plist
launchctl start /Library/LaunchDaemons/com.bauer.tempadmin.plist

#Get a list of users who are in the admin group
adminUsers=$(dscl . -read Groups/admin GroupMembership | cut -c 18-)

#Check if the logged in user is in the admin group and show jamfHelper message
if [[ "$adminUsers" == *"$LoggedInUser" ]]; then
  echo "$LoggedInUser is now an admin"
  #Kill bitbar to read to hostname
  killall BitBarDistro

  #Show jamfHelper message to advise admin rights given
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "🔓 Administrator Privileges Granted for 1 hour" -description "$RealName now has admin rights on $hostName for 60 minutes

After "$adminPeriod1$adminPeriod2" "$checkValueEntered1$checkValueEntered2" admin privileges will be automatically removed and you will not be able to request them again for 24 hours.

During the "$adminPeriod1$adminPeriod2" "$checkValueEntered$checkValueEntered2" of elevated privileges please remember....

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
