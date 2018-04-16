#!/bin/bash

#####################################################
####### Check Host Name matches Computer Name #######
#####################################################

ComputerName=`scutil --get ComputerName`
HostName=`scutil --get HostName`

if [[ "$HostName" == "$ComputerName" ]]; then

echo "Host Name is correct"

else

scutil --set HostName "$ComputerName"

echo "Host Name has been fixed"

fi

exit 0
