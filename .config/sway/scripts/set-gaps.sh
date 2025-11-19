#!/usr/bin/env bash

target=$1
if [[ -z "$target" ]]; then
    exit
fi

DEFAULT_INNER=4
DEFAULT_OUTER=8

current_ws="$(swaymsg -t get_workspaces | jq '.[]|select(.focused).id' -r)"
has_target="$(swaymsg -t get_tree | jq \
    --argjson cur "$current_ws" --argjson target "$target" \
    '.nodes.[]|select(.name != "__i3")|{
        screen: .rect,
        ws: (.nodes.[]|select(.id == $cur).rect)
    }|if .screen.width - .ws.width == $target then 1 else 0 end')"

if ((has_target)); then
    outer=$DEFAULT_OUTER
    inner=$DEFAULT_INNER
else
    outer=$target
    inner=$(echo "$target 0.621 / p" | dc)
fi
swaymsg "gaps outer current set $outer; gaps inner current set $inner"
