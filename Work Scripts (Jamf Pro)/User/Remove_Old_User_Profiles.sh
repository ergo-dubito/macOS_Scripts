#!/bin/sh
##################################################################################
############### Remove old Users Script ##########################################
############### written by Ben Carter & Phil Walker March 2017 ###################
##################################################################################

#Remove all user accounts not modified in the last 90 days (excludes admin and Shared)

oldUsers=$(find /Users -type d -mmin +$((60*24*90)) -maxdepth 1 -not -name "." -not -name "admin" -not -name "Shared" -not -name "Users" | cut -d"/" -f3)

for users in $oldUsers; do
  echo "Checking for old accounts"
    if [[ $users = "admin" ]]; then next
    elif [[ $users = "Shared" ]]; then next
    else
        jamf deleteAccount -username $users -deleteHomeDirectory
        rm -Rf /Users/$users
    fi
done
exit 0
