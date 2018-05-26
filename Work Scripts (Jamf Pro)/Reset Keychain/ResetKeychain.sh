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
UserHomeDirectory=$(/usr/bin/dscl . -read Users/"${LoggedInUser}" NFSHomeDirectory | awk '{print $2}')

#Get the current user's default (login) keychain
CurrentLoginKeychain=$(su "${LoggedInUser}" -c "security list-keychains" | grep login | sed -e 's/\"//g' | sed -e 's/\// /g' | awk '{print $NF}')

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
  chown $LoggedInUser:staff "$KeychainBackup"
  chmod 755 "$KeychainBackup"
else
    rm -Rf "$KeychainBackup"/*
fi
}

function loginKeychain() {
#Check the login default keychain and move it to the backup directory if required
if [[ -z "$CurrentLoginKeychain" ]]; then
  echo "Default login keychain not found"
else
  echo "Default Login Keychain found and now being moved to the backup location..."
  mv "${UserHomeDirectory}/Library/Keychains/$CurrentLoginKeychain" "$KeychainBackup"
fi

}

function checkLocalKeychain() {
#Check the Hardware UUID matches the Local Keychain and move it to the backup directory if required
if [[ "$HardwareUUID" == "$LocalKeychain" ]]; then
  echo "Local Keychain found and matches the Hardware UUID, backing up Local Items Keychain..."
  mv "${UserHomeDirectory}/Library/Keychains/$LocalKeychain" "$KeychainBackup"
elif [[ "$LocalKeychain" != "" ]]; then
  echo "Local Keychain found but does not match Hardware UUID so must have been restored, backing up Local Items Keychain..."
  mv "${UserHomeDirectory}/Library/Keychains/$LocalKeychain" "$KeychainBackup"
else
  echo "Local Keychain not found so nothing to back up"
fi
}

function timeMachineCheck ()
{
#Check if Backup partition is present and not empty
BackupPartition=`diskutil list | grep "Backup" | awk '{ print $3 }'`
BackupContent=$(ls -A /Volumes/Backup/ 2>/dev/null | grep "Backups.backupdb")
#Check the Backup modification date
DATE=`date | awk '{print $2,$3,$4}'`
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
  		echo "Backup is recent, keychain can be restored from a Time Machine backup if required"
      rm -f ${UserHomeDirectory}/Library/Keychains/"$CurrentLoginKeychain"
      rm -Rf ${UserHomeDirectory}/Library/Keychains/"$LocalKeychain"
      echo "Login and Local Items Keychain deleted, Mac will now reboot to complete the process"
  fi
fi
}

#Quit all open apps
read -r -d '' OSASCRIPT_COMMAND <<EOD
set white_list to {"Finder","Self Service","Terminal"}
tell application "Finder"
	set process_list to the name of every process whose visible is true
end tell
repeat with i from 1 to (number of items in process_list)
	set this_process to item i of the process_list
	if this_process is not in white_list then
		try
			tell application this_process
				quit saving yes
			end tell
		on error
			# do nothing
		end try
	end if
end repeat
EOD


##########################
### script starts here ###
##########################

echo "Default Login Keychain: $CurrentLoginKeychain"
echo "Hardware UUID: $HardwareUUID"
echo "Local Items Keychain:$LocalKeychain"

/usr/bin/osascript -e "${OSASCRIPT_COMMAND}"

timeMachineCheck

shutdown -r +1

exit 0
