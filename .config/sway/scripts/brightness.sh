#!/usr/bin/env bash

function has_internal {
    [[ "$(ls /sys/class/backlight/* 2>/dev/null)" != "" ]] && command -v brightnessctl 2>/dev/null
    return $?
}

case "$1" in
get)
    if has_internal; then
        brightnessctl -P get
    else
        ddcutil -d 1 getvcp 10 --lazy-sleep --sleep-multiplier 0.1 -t | cut -d" " -f4 | grep -v "Retrying"
    fi
    ;;
set)
    delta="$2"
    if has_internal; then
        if ((delta < 0)); then
            brightnessctl set $delta%-
        else
            brightnessctl set $delta%+
        fi
        new_current=$(brightnessctl -P get)
        "$XDG_CONFIG_HOME/eww/bin/center_popup.sh" bright 2
        eww update brightness="$new_current"
    else
        current="$(eww get brightness)"
        ((new = current + delta))
        ((new = new >= 100 ? 100 : (new <= 0 ? 0 : new)))
        eww update brightness="$new"
        "$XDG_CONFIG_HOME/eww/bin/center_popup.sh" bright 2
        for ((d = 1; d <= $(swaymsg -t get_outputs | jq 'length'); d++)); do
            ddcutil setvcp 10 -d $d $new --lazy-sleep --disable-dynamic-sleep --sleep-multiplier 0.1 >/dev/null
        done
    fi
    ;;
rawset)
    new="$2"
    if has_internal;  then
        brightnessctl set $new%
    else
        for ((d = 1; d <= $(swaymsg -t get_outputs | jq 'length'); d++)); do
            ddcutil setvcp 10 -d $d $new --lazy-sleep --disable-dynamic-sleep --sleep-multiplier 0.1 >/dev/null 2>&1
        done
    fi
    eww update brightness="$new"
esac
