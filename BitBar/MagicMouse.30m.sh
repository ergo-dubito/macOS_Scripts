#!/bin/bash
# <bitbar.title>Apple Magic Mouse battery</bitbar.title>
# <bitbar.version>1.0</bitbar.version>
# <bitbar.author>Phil Walker</bitbar.author>
# <bitbar.author.github>pwalker1485</bitbar.author.github>
# <bitbar.desc>Displays battery percentage for Apple Magic Mouse</bitbar.desc>
# <bitbar.image>https://i.imgur.com/7pICO5M.png</bitbar.image>

# Works with Magic Mouse and Magic Mouse 2

MM=$(ioreg -n BNBMouseDevice | grep "BatteryPercent" | grep -F -v \{ | sed 's/[^[:digit:]]//g')
MM2=$(system_profiler SPBluetoothDataType | grep -A 6 "Magic Mouse 2" | grep "Battery Level" | awk '{print $3}' | sed 's/%//g')
CHARGE=$(system_profiler SPUSBDataType | grep "Magic Mouse 2" | sed 's/://g' 2>/dev/null | wc -l)

function chargeStatus() {
#display lightning icon if Magic Mouse 2 is charging
if [ $CHARGE -gt 0 ]; then
  echo "🖱⚡️"
fi
}

function magicMouse() {
#Magic Mouse Battery Percentage
if [ $MM ]; then
  if [ $MM -le 20 ]; then
    echo "🖱$MM% | color=red"
  else
    echo "🖱$MM%"
  fi
elif [ $MM2 ]; then
  if [ $MM2 -le 20 ]; then
    echo "🖱$MM2% | color=red"
  else
    echo "🖱$MM2%"
  fi
fi
}

function chargeRequired() {
if [ $MM2 ]; then
  if [ $MM2 -le 20 -a $MM2 -ge 11 ]; then
  echo "🔋Level Low | color=red"
elif [ $MM2 -le 10 ]; then
  echo "🔋Level Critical | color=red"
  echo "⚡️Charge Required | color=red"
  fi
fi
}

echo "$(chargeStatus)$(magicMouse)"
echo "---"
echo "$(chargeRequired)"
