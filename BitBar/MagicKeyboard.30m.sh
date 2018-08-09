#!/bin/bash
# <bitbar.title>Apple Magic Keyboard Status</bitbar.title>
# <bitbar.version>2.0</bitbar.version>
# <bitbar.author>Phil Walker</bitbar.author>
# <bitbar.author.github>pwalker1485</bitbar.author.github>
# <bitbar.desc>Displays charge status or battery percentage for an Apple Magic Keyboard</bitbar.desc>
# <bitbar.image>http://i.imgur.com/CtqV89Y.jpg</bitbar.image>

# Works with Magic Keyboard and Magic Keyboard 2

MK=$(ioreg -c AppleBluetoothHIDKeyboard | grep "BatteryPercent" | grep -F -v \{ | sed 's/[^[:digit:]]//g')
MK2=$(system_profiler SPBluetoothDataType | grep -A 6 "Magic Keyboard" | grep "Battery Level" | awk '{print $3}' | sed 's/%//g')
CHARGE=$(ioreg -p IOUSB -w0 | sed 's/[^o]*o //; s/@.*$//' | grep -v '^Root.*' | grep "Magic*")

function chargeStatus() {
#display lightning icon if Magic Keyboard 2 is charging
if [[ $CHARGE == "Magic Keyboard" ]]; then
  echo "⌨️⚡️"
fi
}

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

echo "$(chargeStatus)$(magicKeyboard)"
echo "---"
echo "$(chargeRequired)"
