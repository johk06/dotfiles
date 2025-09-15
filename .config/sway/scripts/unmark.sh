#!/bin/sh
mark="$(swaymsg -t get_tree | jq -r \
'..| ((.nodes? // empty), (.floating_nodes? // empty))[] | select(.focused) |.marks[0]? // empty')"

if [ -n "$mark" ]; then
    swaymsg unmark "$mark"
fi
