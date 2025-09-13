#!/usr/bin/env bash

cur_workspace="$(swaymsg -t get_workspaces | jq -r '.[]|select(.focused).name')"

prefix=""
if [[ "$cur_workspace" == s* ]]; then
    prefix="s"
    cur_workspace="${cur_workspace:1}"
fi

case "$2" in
    next) target=$((cur_workspace+1));;
    prev) target=$((cur_workspace-1));;
esac

if ((target < 1)); then
    target=1
fi

if [[ "$1" == "go" ]]; then
    swaymsg workspace "$prefix$target"
elif [[ "$1" == "push" ]]; then
    swaymsg move window to workspace "$prefix$target", workspace "$prefix$target"
else
    swaymsg move window to workspace "$prefix$target"
fi
