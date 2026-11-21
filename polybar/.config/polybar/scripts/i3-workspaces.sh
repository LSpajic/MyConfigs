#!/usr/bin/env bash

# Prilagodi ovdje imena monitora
MONITOR_A="eDP-1"
MONITOR_B="HDMI-1"

# Dohvati workspaces i sortiraj po broju
i3-msg -t get_workspaces | jq -r --arg MB "$MONITOR_B" '
sort_by(.num)[] |
# Odredi osnovni label (underline ako je fokus)
(if .focused then "%{u#F0C674}%{+u}\(.name)%{-u}" else .name end) as $ws |
# Dodaj točku ako workspace pripada monitoru B
if (.output | contains($MB)) then
    $ws + "·"
else
    $ws
end
' | paste -sd " " -
