#!/bin/sh

list() {
    swaymsg -t get_marks | jq -c '.|sort'
}

list
swaymsg --monitor -t subscribe '["window"]' |
    jq 'if .change == "close" or .change == "mark" then "\n" else "" end' --unbuffered -j |
    while read -r _; do
        list
    done
