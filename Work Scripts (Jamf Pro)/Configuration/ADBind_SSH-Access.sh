#!/bin/bash

########################################################
########## Bind to AD and confgure SSH access ##########
#### Written by Ben Carter and Phil Walker Feb 2018 ####
########################################################

#
# Get the current geographic location from the IP range
# Add new IP ranges here as required
#
# ** Warning ** If you add a new city code, make sure the AD OU exists FIRST
#

theLoc=`ifconfig | awk '/inet[^6]/{split($2,ip,".");theip=ip[1] "." ip[2] ".";$0=theip}

	$0 == "10.1."	{print "lon"}
	$0 == "10.3."	{print "lon"}
	$0 == "10.101."	{print "lon"}
	$0 == "10.102."	{print "lon"}
	$0 == "172.26."	{print "lon"}
	$0 == "10.176."	{print "lon"}

	$0 == "10.96."  {print "pbo"}
	$0 == "10.116."	{print "pbo"}
	$0 == "10.168." {print "pbo"}

    $0 == "10.66." {print "gla"}
    $0 == "10.77." {print "gla"}
    $0 == "10.56." {print "man"}
    $0 == "10.67." {print "abe"}
	$0 == "10.71." {print "ayr"}
	$0 == "10.73." {print "bel"}
	$0 == "10.69." {print "bir"}
	$0 == "10.72." {print "car"}
	$0 == "10.70." {print "dun"}
	$0 == "10.68." {print "edi"}
	$0 == "10.76." {print "far"}
	$0 == "10.81." {print "gal"}
	$0 == "10.53." {print "hul"}
	$0 == "10.65." {print "inv"}
	$0 == "10.55." {print "lee"}
	$0 == "10.59." {print "liv"}
	$0 == "10.58." {print "new"}
	$0 == "10.57." {print "pre"}
	$0 == "10.54." {print "she"}
	$0 == "10.52." {print "sto"}
	$0 == "10.38." {print "not"}

' | head -n 1`

####### Variables #######

theUser="applebind"									# Username for AD bind account
thePass="appJ45bind"								# password for the AD account
theDomain="bauer-uk.bauermedia.group"				# AD forest for bind
ipAddresses=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1') #Get the IP addresses for all active adaptors
hostName=`/usr/local/jamf/bin/jamf getComputerName | sed -E 's/^[^>]+>//;s/<[^>]+>//;s/_.*$//'`	# the hostname for this Mac
casper_admins="E746DA41-F686-4F95-8DA6-BD639CE88CF2"
casper_superusers="06966C02-B63E-4814-ACF6-E150CCCE92D7"
ADBound=$(dsconfigad -show | awk '/Active Directory Domain/{print $NF}')

####### Functions #######

function adCheck() {
ping -c1 -W5 -q bauer-uk.bauermedia.group &> /dev/null
  if [[ "$?" != "0" ]]; then
    echo "Mac not connected to corporate network"
    exit 1
  else
    echo "Mac connected to corporate network"
fi
}


function checkBind() {
dscacheutil -flushcache

sleep 2

# Check if the computer is on the network by reading its own computer object from AD

    # Get Domain from full structure, cut the name and remove space.
    ShortDomainName=$(dscl /Active\ Directory/ -read . | grep SubNodes | sed 's|SubNodes: ||g')

    computer=$(dsconfigad -show | grep "Computer Account" | awk '{ print $4 }')
    dscl /Active\ Directory/$ShortDomainName/All\ Domains -read /Computers/$computer RecordName &>/dev/null

    if [ ! $? == 0 ] ; then
          echo "No connection to the domain"
          exit 1
    else
          echo "Mac already bound and connected to $ShortDomainName"
    fi
}

function configureSSH() {
# Create new SACL group

  dseditgroup -o create -q com.apple.access_ssh

# Recreate casadmin access in the new SACL group

  dseditgroup -o edit -a "casadmin" -t user com.apple.access_ssh

# Add the AD groups to the new SACL group

  dseditgroup -o edit -a "rol-adm-uk-casper_admins" -t group com.apple.access_ssh
  dseditgroup -o edit -a "rol-adm-uk-casper_superusers" -t group com.apple.access_ssh

# Add the AD groups to the Admin group on the Mac client

  dseditgroup -o edit -a "rol-adm-uk-casper_admins" -t group admin
  dseditgroup -o edit -a "rol-adm-uk-casper_superusers" -t group admin

  echo "members of rol-adm-uk-casper_admins and rol-adm-uk-casper_superusers can now SSH to this Mac ($hostName)"

}

function check4Group() {
sshgroup=`dscl . list /groups | grep "com.apple.access_ssh"`
sshgroupmembers=`dseditgroup com.apple.access_ssh | awk '{print $1}' | grep -E ""$casper_admins"|"$casper_superusers"|casadmin" | wc -l`

if [ "$sshgroup" == "com.apple.access_ssh" ] && [[ "$sshgroupmembers" -eq 3 ]]; then
  echo "SSH Group already present and configured correctly"
        exit 0
else
  echo "configuring SSH Access"
    configureSSH
        exit 0
fi

}

function checksshConfig() {
sshgroup=`dscl . list /groups | grep "com.apple.access_ssh"`
sshgroupmembers=`dseditgroup com.apple.access_ssh | awk '{print $1}' | grep -E ""$casper_admins"|"$casper_superusers"|casadmin" | wc -l`

if [ "$sshgroup" == "com.apple.access_ssh" ] && [[ "$sshgroupmembers" -eq 3 ]]; then
  echo "SSH Group already present and configured correctly"
    exit 0
  else
    echo "configuring SSH Access failed - Rebind ($hostName) to the domain"
      exit 1
fi
}

function performADBind ()
{
	theOU="OU=_mac,OU=_computers,OU=$theLoc,OU=uk,OU=bauer,DC=bauer-uk,DC=bauermedia,DC=group"
	/usr/local/jamf/bin/jamf bind -type ad -domain "$theDomain" -computerID "$hostName" -username "$theUser" -password "$thePass" -ou "$theOU" -cache -defaultShell /bin/bash -localHomes
}

###############################################
#                                             #
#              script starts here             #
#                                             #
###############################################


if [[ "$ADBound" == "" ]]; then

  echo "This Mac ($hostName) is not bound to AD"
  adCheck
  performADBind
  checkBind
  check4Group
  sleep 3
  checksshConfig

else

  adCheck
  checkBind
  check4Group
  sleep 3
  checksshConfig

fi

exit 0
