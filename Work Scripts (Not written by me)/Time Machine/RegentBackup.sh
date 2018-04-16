#!/bin/sh
#######################################################################
############### Profile Backup Script #############################
############### written by Ben Carter March 2017 ###################
#######################################################################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"

#Get the hostname
hostName=`scutil --get HostName`

#Define what the external HDD should be named
regentHDD="/Volumes/RegentProject"
regentHDDshort="RegentProject"

#Define paths for Time Machine
Applications="/Volumes/Macintosh HD/Applications"
Library="/Volumes/Macintosh HD/Library"
System="/Volumes/Macintosh HD/System"
usr="/Volumes/Macintosh HD/usr"
swapFile="/Volumes/Macintosh HD/var/vm"
Backup="/Volumes/RegentProject"
AdminUser="/Volumes/Macintosh HD/Users/admin"
CheckBackup=`diskutil list | grep "RegentProject" | awk '{ print $3 }'`

#Get some totals
regentHDSize=$(df -k $regentHDD | awk '{print $2}' | tail -1)
regentHDSizeHuman=$(df -kH $regentHDD | awk '{print $2}' | tail -1)
regentHDAvailable=$(df -k $regentHDD | awk '{print $4}' | tail -1)
regentHDAvailableHuman=$(df -kH $regentHDD | awk '{print $4}' | tail -1)
#userProfileSize=`du -shI /Users/ | awk '{print $1}'`
userProfileSize=$(du -shI /Users/* | grep -v "admin")
userProfileSizeTotalHuman=$(du -sh /Volumes/Macintosh\ HD/Users/ | awk '{print $1}')
########################################################################
#################### Functions to be used by the script ################
########################################################################
function getExcludedUser1 ()
{
excludedUser1=$(su - $LoggedInUser -c /usr/bin/osascript <<EndGetUser1
tell application "System Events"
    activate
    set the_results to (display dialog ("Enter the 1st profile name to not BackUp - all lowercase no spaces - You can also enter Shared to exclude the Shared folder found in the Users directory") with title ("Exclude User") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results
    set wks to text returned of the_results
end tell
EndGetUser1
)
echo "Excluded User is : $excludedUser1"
}

function getExcludedUser2 ()
{
excludedUser2=$(su - $LoggedInUser -c /usr/bin/osascript <<EndGetUser2
tell application "System Events"
    activate
    set the_results_2 to (display dialog ("Enter the 2nd profile name to not BackUp - all lowercase no spaces") with title ("Exclude User") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results_2
    set wks to text returned of the_results_2
end tell
EndGetUser2
)
echo "Excluded User is : $excludedUser2"
}

function getExcludedUser3 ()
{
excludedUser3=$(su - $LoggedInUser -c /usr/bin/osascript <<EndGetUser3
tell application "System Events"
    activate
    set the_results_3 to (display dialog ("Enter the 3rd profile name to not BackUp - all lowercase no spaces") with title ("Exclude User") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results_3
    set wks to text returned of the_results_3
end tell
EndGetUser3
)
echo "Excluded User is : $excludedUser3"
}

function getExcludedUser4 ()
{
excludedUser4=$(su - $LoggedInUser -c /usr/bin/osascript <<EndGetUser4
tell application "System Events"
    activate
    set the_results_4 to (display dialog ("Enter the 4th profile name to not BackUp - all lowercase no spaces") with title ("Exclude User") buttons {"Cancel", "Continue"} default button "Continue" default answer "")
    set BUTTON_Returned to button returned of the_results_4
    set wks to text returned of the_results_4
end tell
EndGetUser4
)
echo "Excluded User is : $excludedUser4"
}

function openTMSysPrefs ()
{
openTM=$(su - $LoggedInUser -c /usr/bin/osascript <<EndopenTM
tell application "System Preferences"
    activate
    set current pane to pane id "com.apple.prefs.backup"
end tell
EndopenTM
)
echo "Opened TM SysPrefs : $excludedUser4"
}

function enableTMMenuBar ()
{
su - $LoggedInUser -c "open '/System/Library/CoreServices/Menu Extras/TimeMachine.menu/'"
}

function enableTMThrottle ()
{
sysctl debug.lowpri_throttle_enabled=0
}

function cleanup ()
{
    #Remove trash from all user profiles
    echo "Removing Trash for all users"
    for dir in /Users/*
    do
        user=`echo $dir | cut -d'/' -f3`
        rm -rf $dir/.Trash/*
        echo -e "Trash has been emptied for:\t$user"
    done
    /usr/local/jamf/bin/jamf flushCaches -flushUsers
    echo "Purge disk cache"
    purge
    echo "Clear CUPS"
    chflags -Rf nouchg /var/spool/cups/*
    rm -rf /var/spool/cups/*
    killall -HUP cupsd
    echo "CUPS folder has been emptied"
    killall jamfHelper
}

function tmExclustions ()
{
		tmutil addexclusion -p "$Applications"
		tmutil addexclusion -p "$Library"
		tmutil addexclusion -p "$System"
		tmutil addexclusion -p "$Backup"
		tmutil addexclusion -p "$AdminUser"
		tmutil addexclusion -p "$usr"
    tmutil addexclusion -p "$swapFile"
    #Check if there is a user to exclude, if so add to TM exclusion list
    if [ -z $excludedUser1 ]; then
        echo "No value for excluded user 1"
    else
        echo "Excluded user1 defined add to TM exclusion list"
        tmutil addexclusion -p "/Users/$excludedUser1"
        tmutil isexcluded /Users/$excludedUser1
    fi
    #Check if there is a user to exclude, if so add to TM exclusion list
    if [ -z $excludedUser2 ]; then
        echo "No value for excluded user 2"
    else
        echo Excluded user2 defined add to TM exclustion list
        tmutil addexclusion -p "/Users/$excludedUser2"
        tmutil isexcluded /Users/$excludedUser2
    fi
    #Check if there is a user to exclude, if so add to TM exclusion list
    if [ -z $excludedUser3 ]; then
        echo "No value for excluded user 3"
    else
        echo Excluded user3 defined add to TM exclustion list
        tmutil addexclusion -p "/Users/$excludedUser3"
        tmutil isexcluded /Users/$excludedUser3
    fi
    #Check if there is a user to exclude, if so add to TM exclusion list
    if [ -z $excludedUser4 ]; then
        echo "No value for excluded user 4"
    else
        echo Excluded user4 defined add to TM exclustion list
        tmutil addexclusion -p "/Users/$excludedUser4"
        tmutil isexcluded /Users/$excludedUser4
    fi
}

function whilteTMBackup ()
{
FILE=/System/Library/CoreServices/backupd.bundle/Contents/Resources/TMHelperAgent.app/Contents/MacOS/TMHelperAgent
	while true ; do
		if [ -n "$(lsof "$FILE")" ] ; then
			#Disable TimeMachine so no further backups are attempted
      echo "Disable TimeMachine as Backup has finished"
		    tmutil disable

    		#Kill the currentjamf Helper message so a new one can pop up to say complete
        echo "Kill backing up JamfHelper message"
    		killall -9 jamfHelper

    		#Launch jamfHelper as the logged in user to avoid errors in the log and to inform the user that backup has completed
        su - $LoggedInUser <<'whilteTMBackup'
			/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "Backup Complete" -description "Please shutdown this Mac so no additional data is written to any user profiles." -button1 "Ok" -defaultButton 1
whilteTMBackup

        #Print the date for the log file.
        echo "END OF BACKUP"
        date | awk '{print $1,$2,$3,$4}'

        #forward all TM messages from syslog to log file on external disk
        syslog -F '$Time $Message' -k Sender com.apple.backupd -k Time ge -2h >> $regentHDD/Backup_$hostName.log
		    exit 0
		else
  			#echo "Not Found"
  			status="no"
		fi
	done
}

function createBackupLog ()
{
    #Create the log file on the external disk, as this is running as the user no need to change perms
    touch $regentHDD/Backup_$hostName.log
    if [ -a $regentHDD/Backup_$hostName.log ]; then
    	echo "TM Backup Log saved to $regentHDD/Backup_$hostName.log"
      chmod 777 $regentHDD/Backup_$hostName.log
    else
    	echo "Can't find the TM Backup Log on $regentHDD"
    fi
    #Open console and the new log file
    #su - $LoggedInUser -c "open -a Console.app '$regentHDD/Backup_$hostName.log'"
}

#Function to create a list of applications that in installed, excludes all the standard OS ones
function appsList ()
{
#find /Volumes/Macintosh\ HD/Applications/* -iname *.app > $regentHDD/$hostName/$hostName.txt
find /Volumes/Macintosh\ HD/Applications/* -iname *.app -not -path "/Volumes/Macintosh\ HD/Applications/Utilities/*" -maxdepth 1 | grep -v 'App Store\|Automator\|Calculator\|Calendar\|Chess\|Contacts\|DVD Player\|Dashboard\|Dictionary\|FaceTime\|Font Book\|Game Center\|Image Capture\|Launchpad\|Mail\|Maps\|Messages\|Mission Control\|Notes\|Photo Booth\|Photos\|Preview\|QuickTime Player\|Reminders\|Safari\|Stickies\|System Preferences\|TextEdit\|Time Machine\|iBooks\|iTunes\|Self Service' | sed 's/Volumes//g;s/Macintosh HD//;s/Applications//g;s/\///g;s/.app//g;s/Utilities//g' > $regentHDD/$hostName-Applications.txt

if [ -a $regentHDD/$hostName-Applications.txt ]; then
	echo "Application list saved to $regentHDD/$hostName-Applications.txt"
	chmod 777 $regentHDD/$hostName-Applications.txt
else
	echo "Can't find the Applications list on $regentHDD"
fi
}

function printerList ()
{
lpstat -p | awk '{print $2}' > $regentHDD/$hostName-Printers.txt

if [ -a $regentHDD/$hostName-Printers.txt ]; then
	echo "Printer list saved to $regentHDD/$hostName-Printers.txt"
  chmod 777 $regentHDD/$hostName-Printers.txt
else
	echo "Can't find the Printer list on $regentHDD"
fi
}


#JamfHelper message asking confirming file sizes
function jamfHelper_readyToGo ()
{
HELPER=$(
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "$hostName - User Profiles backup" -description "$userProfileSize

Total: $userProfileSizeTotalHuman
Backing up to $regentHDD $regentHDSizeHuman ($regentHDAvailableHuman available)

You will be notified when the backup has completed" -button1 "Ok lets Go" -button2 "Not yet" -cancelButton "2" -defaultButton "1"
)
}

#JamfHelper message advising Profile is being cleaned, run as the logged in user so no errors in log - & at end so the script can carry on after jamf helper is launched
function jamfHelper_cleaningProfiles ()
{
su - $LoggedInUser <<'jamfHelper_cleaningProfiles'
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Application\ Support/JAMF/bin/Management\ Action.app/Contents/Resources/Self\ Service.icns -title "Message from Bauer IT" -heading "Cleaning Profiles before backup" -description "Please wait....."  &
jamfHelper_cleaningProfiles
}

#JamfHelper message advising that the backup is in progress
function jamfHelper_BackupInProgress ()
{
#Show a message via Jamf Helper that the update has started - & at end so the script can carry on after jamf helper is launched.
#su - $LoggedInUser <<'jamfmsg2'
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Applications/Time\ Machine.app/Contents/Resources/backup.icns -title "Message from Bauer IT" -heading "    Profile Backup in Progress     " -description "Profiles are currently being backed up.

DO NOT RESTART or TURN OFF

" &
#jamfmsg2
}

#JamfHelper message advising that there is no external hard drive
function jamfHelper_NoExternaldisk ()
{
#Run Jamf Helper as the logged in user to stop errors
su - $LoggedInUser <<'jamfHelper_NoExternaldisk'
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -title "Message from Bauer IT" -heading "External Hard Drive for profile backup not found" -description "In order for $hostName profiles to be backed up an external hard drive must be connected.

The External drive should be formatted and named $regentHDDshort" -button1 "Ok" -defaultButton 1 -icon /System/Library/CoreServices/Problem\ Reporter.app/Contents/Resources/ProblemReporter.icns &
jamfHelper_NoExternaldisk
}

########################################################################
#################### Start the script ################
########################################################################

#Check if Regent Project HD is mounted
if [[ "$CheckBackup" == RegentProject ]]; then
	#Run jamf helper to ask if ready
	jamfHelper_readyToGo
	#If the value is yes then continue
	if [ "$HELPER" == "0" ]; then
    	#Call jamf Helper to show message update has started
		echo "Clicked yes"

    #Turn off Spotlight
    echo "Turn off Spotlight"
    mdutil -avi off

    #Print the date for the log file.
    echo "START OF BACKUP"
    date | awk '{print $1,$2,$3,$4}'

    #Ask for excluded users
    getExcludedUser1
    getExcludedUser2
    getExcludedUser3
    getExcludedUser4

		#Get current apps and save as a text file
		appsList
    #Get the currently installed Printers
    printerList

		#Disable TimeMachine to stop any additional backups to local disk.
		tmutil disable

		#Create a log file for flushing and TM backup data to be sored in
		#createBackupLog

		#Clear out the trash
		jamfHelper_cleaningProfiles
		cleanup
		jamfHelper_BackupInProgress

		#Enable the TM menu bar for progress monitoring
		echo "Enable TM menubar"
		enableTMMenuBar

		#Set TM destination to external HD
		echo "Set the destination"
		tmutil setdestination "$Backup"

		#Set TM exclusions to not backup
		echo "Set exclustions"
		tmExclustions

		#Enable TimeMachine, might be disabled.
    echo "Enable TimeMachine"
		tmutil enable

    #Enable CPU throttling by TM, speed up measure.
    echo "Enable TM CPU throttling"
    enableTMThrottle

    #Open Sys Prefs at TM pane
    echo "Open Sys Prefs at TM Pane"
    openTMSysPrefs

		#Tell Time Machine to do a backup
		echo "Start the backup of $userProfileSizeTotalHuman"
		tmutil startbackup

		#Check that TM backup is completed
		whilteTMBackup

		exit 0

	else
		echo "Clicked not yet"
	fi
else
	echo "$regentHDD external HD not mounted"
	jamfHelper_NoExternaldisk
	exit 1
fi
