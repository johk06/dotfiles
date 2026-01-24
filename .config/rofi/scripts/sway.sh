#!/usr/bin/env bash

ICON="\0icon\x1f"
INFO="\x1finfo\x1f"

read -r -d '' JQ_QUERY <<'JQ'
.nodes.[].nodes[] |
.name as $name |..|
((.nodes? // empty) + (.floating_nodes? // empty))[] |
select(.pid) + {ws: $name}
| "\(.id)\t\(.name)\t\(.app_id? // .window_properties.class)\t\(.ws)"
JQ

if ((ROFI_RETV == 0)); then
    echo -en "\0use-hot-keys\x1ftrue\n\0delim\x1f\t\n"
    while IFS=$'\t' read -r id name class ws; do

        icon="$class"
        if [[ "$class" == "kitty" ]]; then
            case "$name" in
            nv:*) icon="nvim" ;;
            lf:*) icon="file-manager" ;;
            ncmpcpp:*) icon="multimedia-audio-player" ;;
            qalc) icon="qalculator" ;;
            aerc) icon=email ;;
            newsboat) icon=$name ;;
            esac
        fi

        case "$ws" in
        __i3_scratch) workspace="~scratch" ;;
        *) workspace="$ws" ;;
        esac
        printf "%s\n%s$ICON%s$INFO%s\t" "$name" "$workspace - $class" "$icon" "$id"
    done < <(swaymsg -t get_tree | jq -r "$JQ_QUERY")
else
    if ((ROFI_RETV == 10)); then
        swaymsg "[con_id=$ROFI_INFO] move to workspace current" >/dev/null
    fi
    swaymsg "[con_id=$ROFI_INFO] focus" >/dev/null
fi
