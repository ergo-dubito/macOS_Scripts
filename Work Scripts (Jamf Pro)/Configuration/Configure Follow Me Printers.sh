#!/bin/sh
####################################################################################
########################### Follow You Printing Script #############################
################### written by Ben Carter & Phil Walker May 2017 ###################
####################################################################################

#Get the logged in user
LoggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");'`
echo "Current user is $LoggedInUser"

#Full path of PPD to check it is installed before adding the printers - variable appears less reliable than using the full path in both lpadmin commands
prPPDFullPath="/Library/Printers/PPDs/Contents/Resources/RICOH MP C5504"

#Check for Peterborough subnets
NetSUBPBO=$(ifconfig -L | grep "10.168\|10.96" | awk '{print $2}')


function removeExisitingFollowYou ()
{
# Check for any follow you queues that may have been previously installed
for printer in `lpstat -p | awk '{print $2}' | grep -i "print\|msappeqi"`
do
echo Deleting $printer
lpadmin -x $printer
done
}

# Function to add printer, requires 6 variables, -p Name, -d Description, -L Location, smb:// Address, -P PPD driver location, and -o Options e.g. not shared on local machine
function addPBOQueue()
{
#Execute add printer command
echo "Adding : Peterborough Printers"
lpadmin -p "Peterborough_Mac" -E -v smb://MSAPPEQI04.bauer-uk.bauermedia.group/Peterborough_Mac -P /Library/Printers/PPDs/Contents/Resources/RICOH\ MP\ C5504 -D "Peterborough_Mac" -o printer-is-shared=false -o auth-info-required=negotiate -L "Peterborough"

#Check the printer was installed correctly
PBOQueue=`lpstat -p | awk '{print $2}' | grep -i "Peterborough_Mac"`
if [ -z "Peterborough_Mac" ]; then
  echo "Error Peterborough Printer Queue was not added"
  exit 1
else
  echo "Peterborough Printer Queue added"
fi

}

# Function to add printer, requires 6 variables, -p Name, -d Description, -L Location, smb:// Address, -P PPD driver location, and -o Options e.g. not shared on local machine
function addLDNQueue ()
{
#Execute add printer command
echo "Adding : London Printers"
lpadmin -p "London_Mac" -E -v smb://MSAPPEQI03.bauer-uk.bauermedia.group/London_Mac -P /Library/Printers/PPDs/Contents/Resources/RICOH\ MP\ C5504 -D "London_Mac" -o printer-is-shared=false -o auth-info-required=negotiate -L "London"

#Check the printer was installed correctly
LONQueue=`lpstat -p | awk '{print $2}' | grep -i "London_Mac"`
if [ -z London_Mac ]; then
  echo "Error London Printer Queue was not added"
  exit 1
else
  echo "London Printer Queue added"
fi
}

function setDefault ()
{
  #Check if using a Peterboough LAN or Wifi Corp subnet
  if [[ -z $NetSUBPBO ]]; then
    echo "London queue set as last used"
    lpoptions -d London_Mac
  else
    echo "Peterbough queue set as last used"
    lpoptions -d Peterborough_Mac
  fi
}

function jamfHelperPrintersInstalled ()
{
  #Launch jamfHelper to inform the user that the Office 2016 install has completed
  su - $LoggedInUser <<'jamfHelper_printersinstalled'
  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Printers/RICOH/Icons/157D.icns -title 'Message from Bauer IT' -heading 'Follow You Printing Installed' -description 'You can now print from any Ricoh printer by entering your PIN number to select documents to be printed.

If you have forgotton your printing PIN please contact the IT Service Desk.

  ' -button1 "Ok" -defaultButton "1" &
jamfHelper_printersinstalled
}

function jamfHelperPrintersInstallFailed ()
{
  #Launch jamfHelper to inform the user that the Office 2016 install has completed
  su - $LoggedInUser <<'jamfHelper_printersfailed'
  /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType utility -icon /Library/Printers/RICOH/Icons/157D.icns -title 'Message from Bauer IT' -heading 'Follow You Printing Installation Failed' -description 'It looks like something went wrong when trying to install Follow You Printing.

  Please contact the IT Service Desk.

  ' -button1 "Ok" -defaultButton "1" &
jamfHelper_printersfailed
}
###################
#Script Starts here
###################

if [ ! -f "$prPPDFullPath" ]; then
    echo "Print Driver for Follow Printer not found"
    exit 1
else

  removeExisitingFollowYou
  sleep 5

  addPBOQueue
  sleep 5

  addLDNQueue
  sleep 5

  setDefault
  if [[ -z "$LONQueue" && "$PBOQueue" ]]; then
    echo "Error, no printers added"
    jamfHelperPrintersInstallFailed
    exit 1
  else
    jamfHelperPrintersInstalled
    exit 0
  fi
fi
