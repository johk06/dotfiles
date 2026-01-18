#!/bin/sh

IDFILE="$XDG_CACHE_HOME/clipboard-notification"
read -r ID < "$IDFILE"
ID=${ID:-0}

if [ "$1" = "-p" ]; then
    title="Selection"
else
    title="Clipboard"
fi
notify-send -r "$ID" -p "$title" "$(wl-paste $1)" > "$IDFILE"
