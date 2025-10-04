#!/usr/bin/env bash

ICON="\0icon\x1f"
INFO="\x1finfo\x1f"

read -r -d '' JQ_QUERY << 'JQ'
.. | ((.nodes? // empty)
    + (.floating_nodes? // empty))[] 
| select(.pid)
| "\(.id)\t\(.name)\t\(.app_id? // .window_properties.class)\t\(if .focused then 1 else 0 end)"
JQ

if ((ROFI_RETV == 0)); then
    echo -en "\0use-hot-keys\x1ftrue\n\0delim\x1f\t\n"
    while IFS=$'\t' read -r id name class is_active; do
        if ((is_active)); then
            continue
        fi

        icon="$class"
        if [[ "$class" == "kitty" ]]; then
            case "$name" in
                nv:*) icon="nvim" ;;
                lf:*) icon="file-manager" ;;
                qalc) icon="qalculator" ;;
            esac
        fi
        printf "%s\n%s$ICON%s$INFO%s\t" "$name" "$class" "$icon" "$id"
    done < <(swaymsg -t get_tree | jq -r "$JQ_QUERY")
else
    if ((ROFI_RETV == 10)); then
        swaymsg "[con_id=$ROFI_INFO] move to workspace current" > /dev/null
    fi
    swaymsg "[con_id=$ROFI_INFO] focus" > /dev/null
fi
