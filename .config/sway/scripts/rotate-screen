#!/bin/sh

SCREEN="$1"

monitor-sensor |
    grep --line-buffered "Accelerometer orientation changed" |
    while read -r _ _ _ direction; do
        case "$direction" in
        normal) transform=0 ;;
        bottom-up) transform=180 ;;
        left-up) transform=270 ;;
        right-up) transform=90 ;;
        esac
        swaymsg output "$SCREEN" transform "$transform"
    done
