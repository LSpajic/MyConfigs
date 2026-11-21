#!/usr/bin/env bash
# Polybar: Bluetooth headphone battery.
#   connected     ->  <icon> 80%   (yellow <=30%, red <=15%)
#   disconnected  ->  dim icon
# Click handling is in config.ini (left = connect/disconnect, right = mic mode).

MAC="${HEADPHONES_MAC:-A8:E6:E8:89:D3:73}"
ICON=""   # fa-headphones
DIM="#707880" WARN="#F0C674" ALERT="#A54242"

info=$(bluetoothctl info "$MAC" 2>/dev/null)

if ! grep -q "Connected: yes" <<<"$info"; then
  echo "%{F$DIM}$ICON%{F-}"
  exit 0
fi

# "Battery Percentage: 0x50 (80)"
pct=$(sed -n 's/.*Battery Percentage:.*(\([0-9]*\)).*/\1/p' <<<"$info")

if [ -z "$pct" ]; then
  echo "$ICON"
elif [ "$pct" -le 15 ]; then
  printf "%%{F$ALERT}$ICON %3s%%{F-}%%\n" "$pct"
elif [ "$pct" -le 30 ]; then
  printf "%%{F$WARN}$ICON%%{F-} %3s%%\n" "$pct"
else
  printf "$ICON %3s%%\n" "$pct"
fi
