#!/bin/sh

ACCOUNT="$1"
ALIAS="$2"
REASON="$3"
EXISTING="$4"

if [ ! "$EXISTING" -eq 0 ]; then
    reply="$(notify-send -i email "$REASON on Account '$ACCOUNT'" "($ALIAS)" \
        --action=open="Open Aerc")"
    if [ "$reply" = open ]; then
        kitty aerc :"change-tab $ACCOUNT"
    fi
fi
