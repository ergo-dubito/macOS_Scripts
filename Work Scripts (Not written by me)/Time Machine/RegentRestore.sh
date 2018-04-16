#!/bin/sh
#######################################################################
############### Profile Restore Script #############################
############### written by Ben Carter March 2017 ###################
#######################################################################
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`

#Get the hostname
hostName=`scutil --get HostName`

#Define what the external HDD should be named
regentHDD="/Volumes/RegentProject"
regentHDDshort="RegentProject"

#Define folder path
Shared="/Volumes/Macintosh HD/Users/Shared"
UserProfiles="/Volumes/Macintosh HD/Users"

#Check the Regent backup disk is mounted
BackupPartition=`diskutil list | grep "$regentHDDshort" | awk '{ print $3 }'`

#Time Machine variables for when re-enabled locally post restore
Applications="/Volumes/Macintosh HD/Applications"
Library="/Volumes/Macintosh HD/Library"
System="/Volumes/Macintosh HD/System"
usr="/Volumes/Macintosh HD/usr"
Backup="/Volumes/Backup"
AdminUser="/Volumes/Macintosh HD/Users/admin"

########################################################################
#################### Functions to be used by the script ################
########################################################################

function getoldwks ()
{
oldwks=$(su - $LoggedInUser -c /usr/bin/osascript <<EndMigration
tell application "System Events"
	activate
	set the_results to (display dialog ("Enter the wks number of the backup to restore from") with title ("Profile Restore") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
	set BUTTON_Returned to button returned of the_results
	set wks to text returned of the_results
end tell
EndMigration
)
echo "Old wks is : $oldwks"
#Add the wks number to a new variable to create to entire TM backup path
TMBackup=`find $regentHDD/Backups.backupdb/* -iname $oldwks`
}

function removeShared ()
{

#Remove the Shared folder created by the Casper rebuild process
if [[ ! -d "$Shared" ]]; then
	echo "Shared folder not found but will be restored from backup"
fi
	if [[ -d "$Shared" ]]; then
		rm -r "$Shared"
	echo "Casper build Shared folder deleted and will be restored from backup"
fi
}

function restoreProfiles ()
{
tmutil restore $TMBackup/Latest/Macintosh\ HD/Users/* "$UserProfiles" 2>/dev/null
		echo "Users profiles successfully restored"
		killall jamfHelper 2>/dev/null
		jamfHelper_RestoreComplete
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
function jamfHelper_NoBackupFound ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Message from Bauer IT" -heading "Backup Not Found" -description "Had a look on $regentHDD but couldn't find Time Machine backup $oldwks" -button1 "Ok" -defaultButton 1 -icon /System/Library/CoreServices/Problem\ Reporter.app/Contents/Resources/ProblemReporter.icns &
}

#JamfHelper message advising that external disk is not mounted or plugged in
function jamfHelper_NoRegentHDFound ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Message from Bauer IT" -heading "Backup Not Found" -description "Had a look for $regentHDD but couldn't find it" -button1 "Ok" -defaultButton 1 -icon /System/Library/CoreServices/Problem\ Reporter.app/Contents/Resources/ProblemReporter.icns &
}

#JamfHelper message advising that the restore is in progress
function jamfHelper_RestoreInProgress ()
{
#Show a message via Jamf Helper that the update has started - & at end so the script can carry on after jamf helper is launched.
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Time\ Machine.app/Contents/Resources/backup.icns -title "Message from Bauer IT" -heading "    Profile Restore in Progress     " -description "Profiles are currently being Restored.

DO NOT RESTART or TURN OFF

" &
}

#JamfHelper message advising that the restore has completed
function jamfHelper_RestoreComplete ()
{
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "Profile restore on $hostName complete" -description "All User Profiles from $oldwks have now been restored

Time Machine will be configured for the Backup volume if available" -button1 "Ok" -defaultButton "1"
}

########################################################################
#################### Start the script ################
########################################################################


#Check if the regent external hard drive is plugged in
if [[ "$BackupPartition" != "$regentHDDshort" ]]; then

	echo "No Extenral Hard drive found"
    jamfHelper_NoRegentHDFound
else
	#Check if external HD contains a TM backup
	BackupContent=`ls -A /Volumes/RegentProject/ | grep "Backups.backupdb"`
	if [[ "$BackupPartition" == RegentProject && "$BackupContent" != Backups.backupdb ]]; then

		echo "Backup partition is empty and nothing to restore"
		jamfHelper_NoBackupFound
		exit 0

	else
		echo "Backup partition is found and not empty"
	fi

	#Get the wks number for the old mac
	getoldwks
	echo "The location of the backup $TMBackup"

	#Check if the old wks number exists on the backup disk
	if [ ! -z "$TMBackup" ]; then

		jamfHelper_RestoreInProgress

		echo "Yes external HD plugged in carry on"
		removeShared

		echo "Restore Profiles"
		restoreProfiles

		#Copy the log file to the local share folder for reference
		#cp $regentHDD/Restore_$hostName.txt /Volumes/Macintosh\ HD/Users/Shared

		#Change Shared folder and files to correct permissions
		chmod -R 777 "$Shared"

		#Configure TM for local Backup Disk if available
		configureTM

		#ReIndex Spotlight so Outlook searching works now profile has been restored
		reIndexSpotlight

		exit 0
	else

		echo "No backup for $oldwks found"
		jamfHelper_NoBackupFound
		exit 1
	fi

fi
