#!/usr/bin/env bash

killall "wl-mirror" 2>/dev/null && exit

mapfile screen_names < <(swaymsg -t get_outputs | jq -r '.[]|select(.focused|not).name')
buttons=""
for s in "${screen_names[@]}"; do
    buttons="$buttons --extra-button=$s"
done


choice="$(zenity --question --icon=preferences-desktop-display-randr \
    --text="Select Display to Mirror" --title="Monitor Selection" --switch $buttons)"

if [[ -z "$choice" ]]; then
    exit
fi

wl-mirror -F "$choice"
