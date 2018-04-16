#!/bin/bash

#########################################################################
################ Transfer fonts to another Mac ##########################
############# written by Phil Walker September 2017 #####################
#########################################################################

#For this script to complete successfully the logged in user must have an admin account
#the admin acccount must be a member of rol-adm-uk-casper_superusers or rol-adm-uk-casper_admins

#########################
####### Variables #######
#########################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"

#Directory to move directories/files to
Shared="/Users/Shared/"

#User and Group
USER=root
GROUP=wheel

#########################
####### Functions #######
#########################

function getFolderPath ()
{
folderpath1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndFolderPath1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter the file path for the folder containing the fonts") with title ("File Path") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndFolderPath1
)
echo "Folder path is : $folderpath1"
}

function getFontFolder ()
{
fontfolder1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndFontFolder1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter the name of the folder containing the fonts") with title ("Font Folder") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndFontFolder1
)
echo "Folder to be moved : $fontfolder1"
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

function scpFolder() {
scp -r $folderpath1$fontfolder1 "$LoggedInUser"admin@$remotemac1:"$Shared"

echo "$fontfolder1 fonts transfered to $remotemac1"
}

function setPermissionsAndMove() {
ssh -t "$LoggedInUser"admin@$remotemac1 "/usr/bin/sudo bash -c 'chown -R "$USER":"$GROUP" $Shared$fontfolder1;
find $Shared$fontfolder1 -type d -print0 | xargs -0 chmod 755;
find $Shared$fontfolder1 -type f -print0 | xargs -0 chmod 644;
mv $Shared$fontfolder1 "/Library/Fonts"'"

echo "$fontfolder1 fonts access permissions set and moved to /Library/Fonts on $remotemac1"
}

##########################
### script starts here ###
##########################

getFolderPath
getFontFolder
getRemoteMac
scpFolder
setPermissionsAndMove

exit 0
