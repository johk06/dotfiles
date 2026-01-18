#!/usr/bin/env bash

DATEFMT="%Y_%m.%d_%H:%M:%S_sc"
CACHEDIR="$XDG_CACHE_HOME/screenshots"
if [[ ! -d "$CACHEDIR" ]]; then
    mkdir "$CACHEDIR"
fi

function notify {
    local image_format
    printf -v image_format '<img src="%s" alt="Screenshot">' "$2"
    message="Saved screenshot"
    if [[ "$1" == "clip" ]]; then
        wl-copy <"$REPLY" &
        disown
        message="Copied to clipboard"
    fi
    response="$(notify-send "$message" -c "screenshot" "$image_format" -i accessories-screenshot \
        --action=open="Open" \
        --action=edit="Edit" \
        --action=del="Delete")"
    case "$response" in
    open) xdg-open "$2" ;;
    del) rm "$2" ;;
    edit) satty -f "$2" -o "$2" ;;
    esac
}

function create_tmp {
    timestamp="$(date +"$DATEFMT")"
    REPLY="$CACHEDIR/${timestamp}.png"
}

function create_save {
    timestamp="$(date +"$DATEFMT")"
    REPLY="$(xdg-user-dir PICTURES)/Screenshots/${timestamp}.png"
}

function screen {
    screen="$(swaymsg -t get_outputs | jq -r '.[]|select(.focused).name')"
    eval create_"$1"
    if ! grim -o "$screen" "$REPLY"; then
        exit
    fi
    notify "$2" "$REPLY"
}

function region {
    region="$(slurp -w 0 -b '#4c566acc' -s '#ffffff00')"
    eval create_"$1"
    sleep 0.1
    if ! grim -g "$region" "$REPLY"; then
        exit
    fi
    notify "$2" "$REPLY"
}

function window {
    window="$(swaymsg -t get_tree | jq -r \
        '..| ((.nodes? // empty), (.floating_nodes? // empty))[] | select(.focused) |.rect
	    |"\(.x),\(.y) \(.width)x\(.height)"')"
    eval create_"$1"
    if ! grim -g "$window" "$REPLY"; then
        exit
    fi
    notify "$2" "$REPLY"
}

case "$1" in
window)
    window "$2" "$3"
    ;;
region)
    region "$2" "$3"
    ;;
screen)
    screen "$2" "$3"
    ;;
esac
