#!/bin/sh

if [ "$1" = "both" ] || [ "$1" = "wall" ]; then
    if lsusb --verbose | grep -qF 'vial:'; then
        color="$(img:maincolor -s 200 ~/.config/background/wall)"
        vialctl color "$color"
    fi
fi
