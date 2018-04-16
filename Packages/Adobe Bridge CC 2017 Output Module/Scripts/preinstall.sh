#!/bin/bash

#################################################################
############# Check if Bridge CC 2017 is installed ##############
############### written by Phil Walker October 2017 #############
#################################################################

# Script created as part of the package to install the Output Module

BridgeCC="/Applications/Adobe Bridge CC 2017/Adobe Bridge CC 2017.app"

if [ -d "$BridgeCC" ] ; then
	echo "Adobe Bridge CC 2017 installed"
  exit 0
else
  echo "Adobe Bridge CC 2017 not installed"
  exit 1
fi
