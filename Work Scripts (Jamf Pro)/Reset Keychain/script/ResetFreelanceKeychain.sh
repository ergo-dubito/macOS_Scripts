#!/bin/bash

######################################################################
#### Reset Local Items and Login Keychain for freelance accounts #####
############### Written by Phil Walker June 2018 ######################
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

#Check OS version
OS=$(sw_vers -productVersion)


#########################
###### Functions ########
#########################


function deleteLoginKeychain() {
#Check the login default keychain and move it to the backup directory if required
if [[ -z "$CurrentLoginKeychain" ]]; then
  echo "Default Login keychain not found"
else
  if [[ $OS = *"10.11"* ]]; then
  rm -f "${UserHomeDirectory}/Library/Keychains/login.keychain"
else
  rm -f "${UserHomeDirectory}/Library/Keychains/$CurrentLoginKeychain"
  echo "Login Keychain found and now being deleted..."
  fi
fi

}

function deleteLocalKeychain() {
#Check the Hardware UUID matches the Local Keychain and move it to the backup directory if required
if [[ "$LocalKeychain" == "$HardwareUUID" ]]; then
  rm -Rf "${UserHomeDirectory}/Library/Keychains/$LocalKeychain"
  echo "Local Keychain found and matches the Hardware UUID, deleting Local Items Keychain..."
  elif [[ "$LocalKeychain" != "$HardwareUUID" ]]; then
  rm -Rf "${UserHomeDirectory}/Library/Keychains/$LocalKeychain"
  echo "Local Keychain found but does not match Hardware UUID so must have been restored, deleting Local Items Keychain..."
  else
  echo "Local Keychain not found so nothing to delete"
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
  echo "Keychain deletion FAILED"
  exit 1
fi
}


##########################
### script starts here ###
##########################

echo "Default Login Keychain: $CurrentLoginKeychain"
echo "Hardware UUID: $HardwareUUID"
echo "Local Items Keychain:$LocalKeychain"

if [[ $LoggedInUser != *"freelance"* ]]; then
  echo "Logged in user is not a freelance account so nothing to do"
  exit 1
else
  echo "freelance account logged in so deleting local and login keychains..."
  $loginKeychain
  $localKeychain
fi

$confirmKeychainDeletion

exit 0
