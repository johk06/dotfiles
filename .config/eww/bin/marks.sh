#!/bin/sh
swaymsg --monitor -t subscribe '["window"]' |
    jq 'if .change == "close" or .change == "mark" then "\n" else "" end' --unbuffered -j |
    while read -r _; do
        swaymsg -p -t get_marks | jq -c '.|sort'
        echo
    done
