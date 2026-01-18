#!/usr/bin/env bash

IFS=$'\t' read -ra marks < <(swaymsg -t get_marks | jq -jr '.[]|"\(.)\t"')

if [[ "$1" == initial ]]; then
    max=1
elif [[ "$1" == search ]]; then
    max=-1
fi

mark="$(wayinput -t "Mark" -l "$max" -c "${marks[@]}")"
if [ -n "$mark" ]; then
    swaymsg "[con_mark=^$mark]" "${@:2}"
fi
