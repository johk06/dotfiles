#!/usr/bin/env bash

what="$1"
cmd="$2"

IFS=$'\n' devices=($(pactl --format=json list ${what}s|jq '.[].name' -r))
current="$(pactl get-default-"${what}")"
num_devices="${#devices[@]}"

dev=""
for ((i=0; i < num_devices; i++)); do
    if [[ "${devices[$i]}" == "$current" ]]; then
        if [[ "$cmd" == "next" ]]; then
            if ((i == num_devices - 1)); then
                dev="${devices[0]}"
            else
                dev="${devices[$i+1]}"
            fi
        else
            if ((i == 0)); then
                dev="${devices[-1]}"
            else
                dev="${devices[$i-1]}"
            fi
        fi
        break
    fi
done

pactl set-default-"$what" "$dev"

if [[ "$what" == "sink" ]]; then
    ~/.config/eww/bin/center_popup.sh audio 1 out
else
    ~/.config/eww/bin/center_popup.sh audio 1 in
fi
