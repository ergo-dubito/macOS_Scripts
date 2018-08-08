#!/bin/bash
# <bitbar.title>Apple Magic Keyboard battery</bitbar.title>
# <bitbar.version>1.0</bitbar.version>
# <bitbar.author>Phil Walker</bitbar.author>
# <bitbar.author.github>pwalker1485</bitbar.author.github>
# <bitbar.desc>Displays battery percentage for Apple Magic Keyboard</bitbar.desc>
# <bitbar.image>http://i.imgur.com/CtqV89Y.jpg</bitbar.image>

# Works with Magic Keyboard and Magic Keyboard 2

MK=$(ioreg -c AppleBluetoothHIDKeyboard | grep "BatteryPercent" | grep -F -v \{ | sed 's/[^[:digit:]]//g')
MK2=$(system_profiler SPBluetoothDataType | grep -A 6 "Magic Keyboard" | grep "Battery Level" | awk '{print $3}' | sed 's/%//g')

function magicKeyboard() {
#Magic Keyboard Battery Percentage
  if [ $MK ]; then
    if [ $MK -le 20 ]; then
      echo "⌨️$MK% | color=red"
    else
      echo "⌨️$MK%"
    fi
elif [ $MK2 ]; then
    if [ $MK2 -le 20 ]; then
      echo "⌨️$MK2% | color=red"
    else
      echo "⌨️$MK2%"
    fi
fi
}

function chargeRequired() {
if [ $MK2 ]; then
  if [ $MK2 -le 20 -a $MK2 -ge 11 ]; then
  echo "🔋Level Low | color=red"
elif [ $MK2 -le 10 ]; then
  echo "🔋Level Critical | color=red"
  echo "⚡️Charge Required | color=red"
  fi
fi
}

echo "$(magicKeyboard)"
echo "---"
echo "$(chargeRequired)"
