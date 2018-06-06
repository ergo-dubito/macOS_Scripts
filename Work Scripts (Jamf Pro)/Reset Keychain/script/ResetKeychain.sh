#!/bin/bash

######################################################################
#### Reset Local Items and Login Keychain for the logged in user #####
############### Written by Phil Walker May 2018 ######################
######################################################################

#########################
####### Variables #######
#########################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"

#Get the current user's home directory
UserHomeDirectory=$(/usr/bin/dscl . -read /Users/"${LoggedInUser}" NFSHomeDirectory | awk '{print $2}')

#Get the current user's default (login) keychain
CurrentLoginKeychain=$(su "${LoggedInUser}" -c "security list-keychains" | grep login | sed -e 's/\"//g' | sed -e 's/\// /g' | awk '{print $NF}')

#Check Pre-Sierra Login Keychain
loginKeychain="${UserHomeDirectory}"/Library/Keychains/login.keychain 2>/dev/null

#Hardware UUID
HardwareUUID=$(system_profiler SPHardwareDataType | grep 'Hardware UUID' | awk '{print $3}')

#Local Items Keychain
LocalKeychain=$(ls "${UserHomeDirectory}"/Library/Keychains/ | egrep '([A-Z0-9]{8})((-)([A-Z0-9]{4})){3}(-)([A-Z0-9]{12})' | head -n 1)

#Keychain Backup Directory
KeychainBackup="${UserHomeDirectory}/Library/Keychains/KeychainBackup"

#########################
###### Functions ########
#########################

function createBackupDirectory() {
#Create a directory to store the previous Local and Login Keychain so that it can be restored
if [[ ! -d "$KeychainBackup" ]]; then
  mkdir "$KeychainBackup"
  chown $LoggedInUser:"BAUER-UK\Domain Users" "$KeychainBackup"
  chmod 755 "$KeychainBackup"
else
    rm -Rf "$KeychainBackup"/*
fi
}

function loginKeychain() {
#Check the login default keychain and move it to the backup directory if required
if [[ -z "$CurrentLoginKeychain" ]]; then
  echo "Default Login keychain not found, nothing to delete or back up"
else
  echo "Login Keychain found and now being moved to the backup location..."
  mv "${UserHomeDirectory}/Library/Keychains/$CurrentLoginKeychain" "$KeychainBackup"
  mv "$loginKeychain" "$KeychainBackup" 2>/dev/null
fi

}

function checkLocalKeychain() {
#Check the Hardware UUID matches the Local Keychain and move it to the backup directory if required
if [[ "$LocalKeychain" == "$HardwareUUID" ]]; then
  echo "Local Keychain found and matches the Hardware UUID, backing up Local Items Keychain..."
  mv "${UserHomeDirectory}/Library/Keychains/$LocalKeychain" "$KeychainBackup"
elif [[ "$LocalKeychain" != "$HardwareUUID" ]]; then
  echo "Local Keychain found but does not match Hardware UUID so must have been restored, backing up Local Items Keychain..."
  mv "${UserHomeDirectory}/Library/Keychains/$LocalKeychain" "$KeychainBackup"
else
  echo "Local Keychain not found, nothing to back up or delete"
fi
}

function timeMachineCheck ()
{
#Check if Backup partition is present and not empty
BackupPartition=`diskutil list | grep "Backup" | awk '{ print $3 }'`
BackupContent=$(ls -A /Volumes/Backup/ 2>/dev/null | grep "Backups.backupdb")
#Check the Backup modification date
DATE=`date | awk '{print $2,$3,$6}'`
BackupDate=`ls -l /Volumes/Backup/Backups.backupdb/* 2>/dev/null | grep "Latest" | awk '{print $6,$7,$11}' | sed 's/-.*//'`

if [[ "$BackupPartition" == Backup && "$BackupContent" != Backups.backupdb ]]; then
        echo "No Backup DB found, KeychainBackup directory will be created..."
        createBackupDirectory
        loginKeychain
        checkLocalKeychain
else
  echo "Backup DB found, checking there is a recent backup..."
  if [[ "$DATE" != "$BackupDate" ]]; then
  		echo "Backup is not recent, KeychainBackup directory will be created..."
      createBackupDirectory
      loginKeychain
      checkLocalKeychain
  else
  		echo "Backup is recent, keychain now being deleted but can be restored from a Time Machine backup if required at a later date"
      rm -f ${UserHomeDirectory}/Library/Keychains/"$CurrentLoginKeychain" 2>/dev/null
      rm -f "$loginKeychain" 2>/dev/null
      rm -Rf ${UserHomeDirectory}/Library/Keychains/"$LocalKeychain" 2>/dev/null
      rm -Rf ${UserHomeDirectory}/Library/Keychains/"$HardwareUUID" 2>/dev/null
  fi
fi
}

function confirmKeychainDeletion() {
#repopulate login keychain variable
CurrentLoginKeychain=$(su "${LoggedInUser}" -c "security list-keychains" | grep login | sed -e 's/\"//g' | sed -e 's/\// /g' | awk '{print $NF}')
#repopulate local items keychain variable
LocalKeychain=$(ls "${UserHomeDirectory}"/Library/Keychains/ | egrep '([A-Z0-9]{8})((-)([A-Z0-9]{4})){3}(-)([A-Z0-9]{12})' | head -n 1)

if [[ -z "$CurrentLoginKeychain" ]] && [[ ! -d "$LocalKeychain" ]]; then
    echo "Login & Local Items Keychains deleted or moved successfully, this Mac will now reboot to complete the process"
else
  echo "Keychain reset FAILED"
  exit 1
fi
}

#JamfHelper message advising that running this will delete all saved passwords
function jamfHelper_ResetKeychain ()
{

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Utilities/Keychain\ Access.app/Contents/Resources/AppIcon.icns -title "Message from Bauer IT" -heading "Reset Keychain" -description "Please save all of your work, once saved select the reset button

Your Keychain will then be reset and your Mac will reboot

❗️All passwords currently stored in your Keychain will be deleted" -button1 "Reset" -button2 "Cancel" -defaultButton 1 -cancelButton 2

}

#JamfHelper message to advise that they have cancelled the request
function jamfHelper_Cancelled ()
{

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarDeleteIcon.icns" -title "Message from Bauer IT" -heading "Reset Keychain" -description "Request cancelled

Nothing has been deleted" -button1 "Ok" -defaultButton 1

}

#JamfHelper message to confirm the cache has been deleted
function jamfHelper_KeychainReset ()
{
su - $LoggedInUser <<'jamfHelper1'
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Utilities/Keychain\ Access.app/Contents/Resources/AppIcon.icns -title "Message from Bauer IT" -heading "Reset Keychain" -description "Your Keychain has now been reset

Your Mac will now reboot to complete the process" &
jamfHelper1
}


##########################
### script starts here ###
##########################

echo "Default Login Keychain: $CurrentLoginKeychain"
echo "Hardware UUID: $HardwareUUID"
echo "Local Items Keychain: $LocalKeychain"

jamfHelper_ResetKeychain 2>/dev/null
if [[ "$?" != "0" ]]; then
	echo "User selected Cancel, Keychain will not be reset"
		jamfHelper_Cancelled
		exit 1
else
  echo "User selected Reset, resetting Keychain..."
fi

#Quit all open Apps
echo "Killing all open applications for $LoggedInUser"
killall -u $LoggedInUser

echo "Checking for a recent Time Machine backup..."
timeMachineCheck

jamfHelper_KeychainReset

sleep 10

killall jamfHelper

shutdown -r now

exit 0
