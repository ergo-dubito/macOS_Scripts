#!/bin/bash

##########################################################################################
#  																				                                               #
#  				This script is to remove dormant accounts              				                 #
#																				                                                 #
# Created by : Suleyman Twana													                                   #
# Version: 1.0																	                                         #
# Date: 06/07/2017																                                       #
#																				                                                 #
##########################################################################################

BackupPartition=`diskutil list | grep "Backup" | awk '{ print $3 }'`

#Check if Backup partition is present

	if [[ "$BackupPartition" != Backup ]]; then

		echo "Backup partition could not be found and no profiles deleted"

exit 0

	else

		echo "Backup partition is found"

fi

#Check if backup partition is empty

BackupContent=`ls -A /Volumes/Backup/ | grep "Backups.backupdb"`

	if [[ "$BackupPartition" == Backup && "$BackupContent" != Backups.backupdb ]]; then

		echo "Backup partition is empty and no profiles deleted"

exit 0

	else

		echo "Backup partition is found and not empty"

fi

#Check the backup modification date

DATE=`date | awk '{print $2,$3,$6}'`
BackupDate=`ls -l /Volumes/Backup/Backups.backupdb/* | grep "Latest" | awk '{print $6,$7,$11}' | sed 's/-.*//'`

	if [[ “$DATE” != “$BackupDate” ]]; then

		echo "Backup is not recent and no profiles deleted"

exit 0

	else

		echo "Backup is recent"

fi

# Create a directory for the temp files if doesn't exist

ProfDir="/tmp/OldProf"

	if [[ ! -d "$ProfDir" ]]; then

	mkdir $ProfDir

fi

# Check home folders with old modification dates but users have no DSCL records

find /Users -type d -mtime +$((730)) -maxdepth 1 -not -name "." -not -name "admin" -not -name "Shared" -not -name "Users" | cut -d"/" -f3 > $ProfDir/OldFolders.txt

dscl . -list /Users | grep -v "_" > $ProfDir/dscl.txt

grep -v -f /private/tmp/OldProf/dscl.txt /private/tmp/OldProf/OldFolders.txt > $ProfDir/homefolderstodelet.txt

while read -r line || [[ -n "$line" ]]; do

		echo "$line"

		rm -Rf /Users/"$line"

done < $ProfDir/homefolderstodelet.txt

# Check all accounts with timestamp

dscl . -list /Users | grep -v "_" > $ProfDir/profiles.txt

while read -r line || [[ -n "$line" ]]; do

		echo "$line"

		printf "%-16s %s\n" "$line" "$(dscl . -read /Users/"$line"/ | grep -i "CopyTimestamp:" | awk '{print $2 }' | sed 's/T.*//g')" | grep -E "20[0-9]{2}\-(0[1-9]|1[0-2])\-([0-2][0-9]|3[0-1])" >> $ProfDir/profilesTS.txt

done < $ProfDir/profiles.txt

# Get the accounts with old time stamp and convert to epoch time

dates=$(cat $ProfDir/profilesTS.txt | awk '{print $2}')

		echo "$dates" > $ProfDir/dates.txt

while read -r line || [[ -n "$line" ]]; do

		echo "$line"

		date -j -f "%Y-%m-%d" "$line" +"%s" >> $ProfDir/epochdates.txt

done < $ProfDir/dates.txt

profandepochdates=$(pr -m -t $ProfDir/profilesTS.txt $ProfDir/epochdates.txt)

	    echo "$profandepochdates" > $ProfDir/profandepochdates.txt

TodayPlus6Months=$(date -v -730d +"%Y-%m-%d")

	    echo "$TodayPlus6Months" > $ProfDir/todayplus6months.txt

TodayPlus6Monthsepoch=$(date -j -f "%Y-%m-%d" "$TodayPlus6Months" +"%s")

while read -r line || [[ -n "$line" ]]; do

		value=$(echo "$line" | awk '{print $3}')

		if [[ "$value" -lt "$TodayPlus6Monthsepoch" ]]; then

		echo "$line" >> $ProfDir/olduserprof.txt

fi

done < $ProfDir/profandepochdates.txt

# Now rename old profiles

while read -r line || [[ -n "$line" ]]; do

		value=$(echo "$line" | awk '{print $1}')

		if [[ -d /Users/"$value" ]]; then

		mv /Users/"$value" /Users/Dormant-"$value"

fi

done < $ProfDir/olduserprof.txt

# Now remove dormant profile home folder and dscl accounts from the Mac

DormantHomeFolder=$(find /Users -iname \*Dormant-\* -type d -maxdepth 1)

# If dormant profiles are present on the Mac, then start the removal process

	if [[ $DormantHomeFolder != "" ]]; then

	find /Users -iname \*Dormant-\* -type d -maxdepth 1 | sed 's/Users//;s/\///g' | sed 's/Dormant-//g' > $ProfDir/Dormant.txt

	rm -r /Users/Dormant-*

# Now remove the DSCL records

while read -r line || [[ -n "$line" ]]; do

		echo "$line"

	dscl . -delete "/Users/$line"

	echo "All dormant profiles and relative home folders are removed"

done < $ProfDir/Dormant.txt

else

# Check if dormant profiles not present on the Mac

	if [[ $DormantHomeFolder == "" ]]; then

		echo "No Dormant profiles are found"

sleep 5

	rm -r $ProfDir

	fi

fi

exit 0
