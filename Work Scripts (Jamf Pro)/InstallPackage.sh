#!/bin/bash

#########################################################################
################ Copy and run package on remote Mac #####################
############## written by Phil Walker September 2017 ####################
#########################################################################

#For this script to complete successfully the logged in user must have an admin account
#the admin acccount must be a member of rol-adm-uk-casper_superusers or rol-adm-uk-casper_admins

#########################
####### Variables #######
#########################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"

#Directory to move package to
Shared="/Users/Shared/"

#########################
####### Functions #######
#########################

function getFolderPath ()
{
folderpath1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndFolderPath1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter the file path for the location of the package") with title ("File Path") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndFolderPath1
)
echo "Folder path is : $folderpath1"
}

function getPackage ()
{
package1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndPackage1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter the name of package you wish to install") with title ("Package Transfer") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndPackage1
)
echo "Package to be moved : $package1"
}

function getRemoteMac ()
{
remotemac1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndRemoteMac1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter the name of the remote Mac") with title ("Remote Mac") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndRemoteMac1
)
echo "Remote Mac is : $remotemac1"
}

function scpPackage() {
scp -r $folderpath1"$package1"*.pkg "$LoggedInUser"admin@$remotemac1:"$Shared"

echo "$package1 transfered to $remotemac1"
}

function installPackage() {
ssh -t "$LoggedInUser"admin@$remotemac1 "/usr/bin/sudo bash -c 'installer -pkg $Shared"$package1"*.pkg -target /;
rm -Rf $Shared"$package1"*.pkg;
/usr/local/bin/jamf recon'"

echo "$package1 installed on $remotemac1, package then removed and recon run"
}

##########################
### script starts here ###
##########################

getFolderPath
getPackage
getRemoteMac
scpPackage
installPackage

exit 0
