#!/bin/sh

##################################################################################
############### Query the stale users accounts ###################################
############### written by Phil Walker and Ben Carter April 2017 #################
##################################################################################

#Home directories not modified in the last 90 days

userList=$(find /Users -type d -mmin +$((60*24*90)) -maxdepth 1 -not -name "." -not -name "admin" -not -name "Shared" -not -name "Users" | cut -d"/" -f3)

echo "<result>Yes - "
for User in $userList ; do
        echo "("
        ls -lT /Users/ | grep "$User" | awk '{print $7,$8,$9,$10}'
        du -hd 0 /Users/$User/ | awk '{print $2, $1}'
        echo ")"
done
echo "</result>"
exit 0
