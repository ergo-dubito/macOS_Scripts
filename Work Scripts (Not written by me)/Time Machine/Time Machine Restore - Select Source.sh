#!/bin/bash

#######################################################################
############### Profile Restore Script with backup source selection ###
############### written by Ben Carter August 2017 #####################
#######################################################################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"
#Get the hostname
hostName=`scutil --get HostName`

#Define what the T keyed Mac should be named

#Define folder path
Shared="/Volumes/Macintosh HD/Users/Shared"
UserProfiles="/Volumes/Macintosh HD/Users"

#Time Machine variables for when re-enabled locally post restore
Applications="/Volumes/Macintosh HD/Applications"
Library="/Volumes/Macintosh HD/Library"
System="/Volumes/Macintosh HD/System"
usr="/Volumes/Macintosh HD/usr"
Backup="/Volumes/Backup"
AdminUser="/Volumes/Macintosh HD/Users/admin"

function askforTMBackupDisk ()
{

TMBackupDisk=$(su - $LoggedInUser -c /usr/bin/osascript <<askit
set theOutputFolder to choose folder with prompt "Please select the folder called wks***** on the Backup Disk:"
set theUNIXPath to POSIX path of theOutputFolder
askit
)
  echo "Backup Disk Location is : $TMBackupDisk"
}

function restoreProfiles ()
{
tmutil restore "$TMBackupDisk"/Latest/Macintosh\ HD/Users/* "$UserProfiles" 2>/dev/null
		echo "Users profiles successfully restored"
		killall jamfHelper 2>/dev/null
		jamfHelper_RestoreComplete 2>/dev/null
}

function removeShared ()
{

#Remove the Shared folder created by the Casper rebuild process
if [[ ! -d "$Shared" ]]; then
	echo "Shared folder not found but will be restored from backup"
fi
	if [[ -d "$Shared" ]]; then
		rm -r "$Shared"
	echo "Shared folder deleted and will be restored from backup"
fi
}

function configureTM ()
{
#Check if Backup volume is present
if mount | grep $Backup; then
#Enable TM
	tmutil enable
	tmutil enablelocal
	#Set Backup volume
	tmutil setdestination "$Backup"
	#Adding System, Library, Applications and Backup partition to TM exclusion list
	tmutil addexclusion -p "$Applications"
	tmutil addexclusion -p "$Library"
	tmutil addexclusion -p "$System"
	tmutil addexclusion -p "$Backup"
	tmutil addexclusion -p "$AdminUser"
	tmutil addexclusion -p "$usr"
	echo "Time Machine configured to Backup Volume"
else
	echo "No Backup Volume is not mounted - Time Machine not configured"
fi
}

function reIndexSpotlight ()
{
# Turn Spotlight indexing off
/usr/bin/mdutil -i off /
# Delete the Spotlight folder on the root level of the boot volume
/bin/rm -rf /.Spotlight*
# Turn Spotlight indexing on
/usr/bin/mdutil -i on /
# Force Spotlight re-indexing on the boot volume
/usr/bin/mdutil -E /
}

#JamfHelper message advising that No backup was found on the external HD
function jamfHelper_IncorrectPathGiven ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Message from Bauer IT" -heading "Backup Not Found" -description "Had a look for $TMBackupDisk couldn't find Time Machine backup

Please select the folder named wks***** to resotre to this Mac" -button1 "Ok" -defaultButton 1 -icon /System/Library/CoreServices/Problem\ Reporter.app/Contents/Resources/ProblemReporter.icns &
}

#JamfHelper message advising that external HD still connected
function jamfHelper_DriveStillMounted ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Message from Bauer IT" -heading "Backup still connected" -description "$TMBackupDisk is still connected!

Please eject so Time Machine can be configured for the local Mac" -button1 "Ok" -defaultButton 1 -icon /System/Library/CoreServices/Problem\ Reporter.app/Contents/Resources/ProblemReporter.icns
}

#JamfHelper message advising that the restore is in progress
function jamfHelper_RestoreInProgress ()
{
#Show a message via Jamf Helper that the update has started - & at end so the script can carry on after jamf helper is launched.
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Time\ Machine.app/Contents/Resources/backup.icns -title "Message from Bauer IT" -heading "    Profile Restore in Progress     " -description "Profiles are currently being Restored from $TMBackupDisk.

DO NOT RESTART or TURN OFF

" &
}

#JamfHelper message advising that the restore has completed
function jamfHelper_RestoreComplete ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "Profile restore on $hostName complete" -description "All User Profiles from $TMBackupDisk have now been restored

Please eject the external Mac or Disk." -button1 "Ok" -defaultButton "1"
}

########################################################################
#################### Start the script ################
########################################################################
``
#ASk for the location of the Time Machine Backup
askforTMBackupDisk

#Check if the folder selected contains a wks number
if [[ $TMBackupDisk == *"WKS"* || $TMBackupDisk == *"wks"* ]]; then
  echo "Selected folder has wks number"
  jamfHelper_RestoreInProgress 2>/dev/null

  echo "Removing Users/Shared folder so it can be restored from TM"
  removeShared

  echo "Restore Profiles"
  restoreProfiles

  echo "Change permissions on Shared folder to 777"
  chmod -R 777 "$Shared"

  #ReIndex Spotlight so Outlook searching works now profile has been restored
  reIndexSpotlight

  #Wait for disk ejection
 while true ; do
   jamfHelper_DriveStillMounted 2>/dev/null
   if [ ! -d "$TMBackupDisk" ] ; then
     echo "$TMBackupDisk ejected"
       sleep 25

       #Configure TM for local Backup Disk if available
       configureTM

       #Kill jamfHelper message advising to unplug external disk or Mac
       killall jamfHelper 2>/dev/null
       exit 0
   else
     echo "$TMBackupDisk Still present"
     sleep 5
   fi
 done
else
  echo "No TimeMachine wks number found"
  jamfHelper_IncorrectPathGiven 2>/dev/null
  exit 1
fi
