#!/bin/sh

if [ "$1" = "deco" ]; then
    BORDER="normal 2"
else
    BORDER="pixel 2"
fi

border="$(swaymsg -t get_tree | jq -r \
    '..| ((.nodes? // empty), (.floating_nodes? // empty))[] | select(.focused) |.border? // "none"')"

if [ "$border" = "none" ]; then
    border="$BORDER"
else
    border="none"
fi

swaymsg '[title=.*]' border "$border" ';' default_border "$border"
