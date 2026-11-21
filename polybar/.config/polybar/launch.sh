#!/usr/bin/env bash

# Ugasi sve instance
killall -q polybar

# Čekaj da se ugase
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Pokreni Polybar na SVAKOM spojenom monitoru
for monitor in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    echo "Launching Polybar on $monitor"
    MONITOR=$monitor polybar main --config=~/.config/polybar/config.ini 2>&1 | tee -a /tmp/polybar.log & disown
done
