#!/bin/bash

# Get default sink info
sink=$(pactl get-default-sink)
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

# Check if muted
if [[ "$volume" == *"[MUTED]"* ]]; then
    echo "🔇 muted"
    exit 0
fi

# Extract percentage number
percent=$(echo "$volume" | awk '{print int($2 * 100)}' )

# Check if active sink is bluetooth, headphone, or sony
if [[ "$sink" == *"bluez"* ]] || [[ "$sink" == *"headphone"* ]] || [[ "$sink" == *"sony"* ]]; then
    echo "🎧 $percent%"
else
    echo "🔊 $percent%"
fi
