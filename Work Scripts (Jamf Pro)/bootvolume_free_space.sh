#!/bin/sh
#####################################################
############# Boot Volume Free Space ################
############# written by Phil Walker ################
#####################################################

#Decimal reading
free=`diskutil info / | grep -e "Volume Free Space" -e "Volume Available Space" | awk '{print $4,$5}'`

#or
#Binary reading
#free=`df -hl / | grep -v "Avail" | awk '{print $4}'`

echo "<result>"$free"</result>"
