#!/bin/bash

RecHDID=`/usr/sbin/diskutil list | grep "Recovery HD" | awk 'END { print $NF }'`

		/usr/sbin/diskutil unmount /dev/"$RecHDID"
		/usr/sbin/asr adjust --target /dev/"$RecHDID" --settype Apple_Boot

exit 0
