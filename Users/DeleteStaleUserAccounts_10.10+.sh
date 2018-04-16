#!/bin/sh

############################################################################
# Removes all user accounts not accessed in the last 90 days - 10.10+ only #
################## Script created by Phil Walker April 2017 ################
############################################################################

userList=$(find /Users -type d -mmin +$((60*24*90)) -maxdepth 1 -not -name "." -not -name "admin" -not -name "Shared" -not -name "Users" | cut -d'/' -f3)

for User in $userList ; do
      sysadminctl -deleteUser $User # Kills all processes for user, removes home directory, removes public share point, deletes record.
      echo "$User has been deleted"
done
exit 0
