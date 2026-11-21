#!/bin/bash

# Get brightness as a percentage
brightness=$(brightnessctl get)
max_brightness=$(brightnessctl max)
percentage=$((brightness * 100 / max_brightness))

echo "$percentage"
