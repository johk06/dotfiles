#!/bin/sh

pid="$(swaymsg -t get_tree | jq -r '.. | ((.nodes? // empty), (.floating_nodes? // empty))[] | select(.focused).pid')"
if [ "$(ps -o state= $pid)" = T ]; then
    kill -CONT $pid
else
    kill -STOP $pid
fi
