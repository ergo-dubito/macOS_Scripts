#!/bin/sh

#Get the IP
theLoc=`ifconfig | awk '/inet[^6]/{split($2,ip,".");theip=ip[1] "." ip[2] ".";$0=theip}

	$0 == "10.1."	{print "London"}
	$0 == "10.3."	{print "London"}
	$0 == "10.101."	{print "London"}
	$0 == "10.102."	{print "London"}
	$0 == "172.26."	{print "Londondon"}

	$0 == "10.96."  {print "Peterborough"}
	$0 == "10.116."	{print "Peterborough"}
	$0 == "10.168." {print "Peterborough"}

' | head -n 1`

if [ $theLoc == "London" ]; then
	DNSSuffix="aca.bauer-uk.bauermedia.group"
elif [ $theLoc == "Peterborough" ]; then
	DNSSuffix="med.bauer-uk.bauermedia.group"
else
	DNSSuffix=""
fi

# Identify Hardware

MacModel=`ioreg -rd1 -c IOPlatformExpertDevice | awk -F'["|"]' '/model/{print $4}' | sed 's/[0-9]*//g;s/,//g'`

echo "Mac model : $MacModel with the location of $theLoc"

function checkEthernetDomainsMacPro() {

DomainsEthernet1=`/usr/sbin/networksetup -getsearchdomains "Ethernet 1" | grep "bauer" | wc -l`
DomainsEthernet2=`/usr/sbin/networksetup -getsearchdomains "Ethernet 2" | grep "bauer" | wc -l `
if [[ $DomainsEthernet1 -eq "2" ]] && [[ $DomainsEthernet2 -eq "2" ]]; then
	  echo "$MacModel Ethernet Search Domains correct, nothing to add"
else
  echo "Adding Search Domains for interfaces Ethernet 1 and Ethernet 2 on $MacModel"
  /usr/sbin/networksetup -setsearchdomains "Ethernet 1" $DNSSuffix bauer-uk.bauermedia.group
  /usr/sbin/networksetup -setsearchdomains "Ethernet 2" $DNSSuffix bauer-uk.bauermedia.group
fi

}

function checkEthernetDomains() {

DomainsEthernet=`/usr/sbin/networksetup -getsearchdomains "Ethernet" | grep "bauer" | wc -l`
if [[ "$DomainsEthernet" -eq "2" ]]; then
  echo "$MacModel Ethernet Search Domains correct, nothing to add"
else
  echo "Adding Search Domains for Ethernet interface on $MacModel"
  /usr/sbin/networksetup -setsearchdomains "Ethernet" $DNSSuffix bauer-uk.bauermedia.group
fi

}

function checkWiFiDomains() {

DomainsWiFi=`/usr/sbin/networksetup -getsearchdomains "Wi-Fi" | grep "bauer" | wc -l`
if [[ "$DomainsWiFi" -eq "2" ]]; then
  echo "$MacModel Wifi Search Domains correct, nothing to add"
else
  echo "Adding Search Domains for Wi-Fi interface on $MacModel"
  /usr/sbin/networksetup -setsearchdomains "Wi-Fi" $DNSSuffix bauer-uk.bauermedia.group
fi

}

function confirmDomainsMP() {

DomainsEthernet1=`/usr/sbin/networksetup -getsearchdomains "Ethernet 1" | grep "bauer" | wc -l`
DomainsEthernet2=`/usr/sbin/networksetup -getsearchdomains "Ethernet 2" | grep "bauer" | wc -l`

if [[ $MacModel = "MacPro" ]]; then
  if [[ $DomainsEthernet1 -eq "2" ]] && [[ $DomainsEthernet2 -eq "2" ]]; then
    echo "$MacModel Ethernet Search Domains added successfully"
else
    echo "$MacModel Ethernet Search Domains not added"
    exit 1
  fi
fi

}


function confirmDomainsMBA() {

DomainsWiFi=`/usr/sbin/networksetup -getsearchdomains "Wi-Fi" | grep "bauer" | wc -l`

if [[ $MacModel = "MacBookAir" ]]; then
  if [[ $DomainsWiFi -eq "2" ]]; then
    echo "$MacModel Wifi Search Domains added successfully"
else
    echo "$MacModel Wifi Search Domains not added"
    exit 1
  fi
fi

}

function confirmDomains() {

DomainsWiFi=`/usr/sbin/networksetup -getsearchdomains "Wi-Fi" | grep "bauer" | wc -l`
DomainsEthernet=`/usr/sbin/networksetup -getsearchdomains "Ethernet" | grep "bauer" | wc -l`

if [[ $DomainsWiFi -eq "2" ]] && [[ $DomainsEthernet -eq "2" ]]; then
    echo "Search Domains Correct"
else
    echo "Search Domains not added"
    exit 1
fi

}


if [[ $MacModel = "MacPro" ]]; then

    checkEthernetDomainsMacPro
    confirmDomainsMP

elif [[ $MacModel = "MacBookAir" ]]; then

    checkWiFiDomains
    confirmDomainsMBA

else
  # For all other models i.e iMac, MacBook Pro and Mac Mini

    checkWiFiDomains
    checkEthernetDomains
    confirmDomains
fi


exit 0
