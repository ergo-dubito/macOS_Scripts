#!/bin/sh

#################################################
############# Mac Last Boot Time ################
########### written by Phil Walker ##############
#################################################

LastBoot=$(date -jf "%s" "$(sysctl kern.boottime | awk -F'[= |,]' '{print $6}')" +"%d-%m-%Y %T")

echo "<result>"$LastBoot"</result>"

exit 0
