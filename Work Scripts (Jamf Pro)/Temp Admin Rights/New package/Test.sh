#!/bin/bash

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

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

getAdminTime1

if [[ "$adminPeriod1" =~ [^[:digit:]] ]]; then
    echo "Period entered contains non digits and must be re-entered"
    getAdminTime2
else
    echo "Period entered contains only digits"
    if [[ "$adminPeriod1" -eq "10" ]] || [[ "$adminPeriod1" -eq "1" ]] || [[ "$adminPeriod1" -eq "3" ]] || [[ "$adminPeriod1" -eq "6" ]]; then
      echo "Period entered accepted"
    else
      echo "Period entered incorrect"
      getAdminTime2
    fi
fi

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

exit 0
