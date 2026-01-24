#!/usr/bin/env bash

ICON="\0icon\x1f"
ACTIVE="\0active\x1f"
SET_DELIM="\0delim\x1f"
META="\x1fmeta\x1f"
INFO="\x1finfo\x1f"

function hacky_get_sink_name {
    IFS="=" read _ title < <(pactl list sink-inputs | grep "Sink Input #$1" -A 27 | tail -n 1)
    REPLY="${title:2:-1}"
}

function print_streams {
    i=0
    active=""
    while IFS=$'\t' read -r sink muted appname appprog title; do
        # HACK: pactl cant handle non ascii titles, do it for ourselves
        if [[ "$title" == "(null)" ]]; then
            hacky_get_sink_name "$sink"
            title="$REPLY"
        fi
        if [[ "$muted" == true ]]; then
            active+="$i,"
            appname+="- Muted"
        fi
        ((i++))
        printf "%s\n%s$ICON%s$INFO%s\t" "$title" "$appname" "$appprog" "$sink"
    done < <(pactl --format=json list sink-inputs | jq -r '.[]|"\(.index)\t\(.mute)\t\(.properties."application.name")\t\(.properties."application.process.binary")\t\(.properties."media.name")"')
    echo -en "$ACTIVE$active\t"
}
if ((ROFI_RETV != 0)); then
    pactl set-sink-input-mute "$ROFI_INFO" toggle
else
    echo -en "$SET_DELIM\t\n"
fi
print_streams
