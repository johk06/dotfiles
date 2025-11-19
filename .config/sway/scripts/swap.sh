#!/bin/sh

direction="$1"
mark="$(swaymsg -t get_tree | jq -r \
    '..| ((.nodes? // empty), (.floating_nodes? // empty))[] | select(.focused) |.marks[0]? // empty')"

swaymsg "mark swap; focus $direction; swap container with mark swap; [con_mark=^swap$] focus; unmark swap"
if [ -n "$mark" ]; then
    swaymsg mark "$mark"
fi
