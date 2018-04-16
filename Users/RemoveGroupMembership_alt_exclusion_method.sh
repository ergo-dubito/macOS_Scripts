#!/bin/sh

#####################################################################
######## Remove user from local group (admin, _developer etc) #######
############ Script created by Phil Walker April 2017 ###############
#####################################################################

# replace variable assignments with group name and users to exclude

exc1=admin
exc2=root
exc3=*admin #wildcard used to exlcude all mobile admin accounts/admin accounts with correct naming convention
GROUP=groupname

grpmembership=$(dscl . read /Groups/$GROUP GroupMembership | cut -c 18-)

for users in $grpmembership; do
  if [[ $users = $exc1 ]]; then
  :
  elif [[ $users = $exc2 ]]; then
  :
  elif [[ $users = $exc3 ]]; then
  :
  else
    dseditgroup -o edit -d $users -t user $GROUP
    echo "$users removed from $GROUP group"
  fi
done
exit 0
