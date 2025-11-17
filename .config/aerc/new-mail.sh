#!/bin/sh

action="$(
    notify-send -i email \
        "[$AERC_ACCOUNT] $AERC_FROM_NAME" \
        "$AERC_SUBJECT" 
)"
