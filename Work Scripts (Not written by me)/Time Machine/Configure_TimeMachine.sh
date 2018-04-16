#!/bin/bash

###################################################
#Setting up Time Machine to backup up users folder#
###################################################

Applications="/Volumes/Macintosh HD/Applications"
Library="/Volumes/Macintosh HD/Library"
System="/Volumes/Macintosh HD/System"
usr="/Volumes/Macintosh HD/usr"
Backup="/Volumes/Backup"
AdminUser="/Volumes/Macintosh HD/Users/admin"
CheckBackup=`diskutil list | grep "Backup" | awk '{ print $3 }'`

#Check if Backup partition is present

	if [[ "$CheckBackup" == Backup ]]; then

#Enable TM

		tmutil enable
		tmutil enablelocal

#Set Backup partition

		tmutil setdestination "$Backup"

#Adding System, Library, Applications and Backup partition to TM exclusion list

		tmutil addexclusion -p "$Applications"
		tmutil addexclusion -p "$Library"
		tmutil addexclusion -p "$System"
		tmutil addexclusion -p "$Backup"
		tmutil addexclusion -p "$AdminUser"
		tmutil addexclusion -p "$usr"


	else
		echo "Backup partition is not mounted"

fi

exit 0
