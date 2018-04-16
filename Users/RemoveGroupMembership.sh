#!/bin/sh

#####################################################################
######## Remove user from local group (admin, _developer etc) #######
############ Script created by Phil Walker April 2017 ###############
#####################################################################

# replace variable assignment with group name

GROUP=groupname

grpmembership=$(dscl . read /Groups/$GROUP GroupMembership | cut -c 18-)

for users in $grpmembership; do
  if [ "$users" != "root" ]  && [ "$users" != "admin" ] && [[ "$users" != *admin ]]; then
    dseditgroup -o edit -d $users -t user $GROUP
      if [ $? = 0 ]; then
      echo "$users removed from $GROUP group"
    else
      echo "$users not removed from $GROUP group"
  fi
fi
done
exit 0
