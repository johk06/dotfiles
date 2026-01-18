#!/usr/bin/env bash

DATEFMT="%Y_%m.%d_%H:%M:%S"
VIDEO_DIR="$(xdg-user-dir "VIDEOS")/Recordings"

function create_file {
    timestamp="$(date +"$DATEFMT")"
    REPLY="$VIDEO_DIR/${timestamp}.mkv"
}

if pkill wf-recorder; then
    exit
fi

screen="$(swaymsg -t get_outputs | jq -r '.[]|select(.focused).name')"
if [[ "$1" == "select" ]]; then
    region="$(slurp -w 0 -b '#4c566acc' -s '#ffffff00')"
    if [[ -z "$region" ]]; then
        exit
    fi
    extra="-g"
    sleep 0.1
fi

create_file
path="$REPLY"

wf-recorder -o "$screen" $extra "$region" -c hevc_vaapi -d /dev/dri/renderD128 -f "$path" -r 60 &
pid=$!
printf -v info '{"start":%s, "pid":%s, "path":"%s"}' $EPOCHSECONDS $pid "$path"
eww update recording=true recording-info="$info"

wait $pid
eww update recording=false recording-info='{}'

CACHEFILE="$XDG_CACHE_HOME/.thumb_$EPOCHSECONDS"
ffmpegthumbnailer -s 512 -m -i "$path" -o "$CACHEFILE"
reply="$(
    notify-send "Finished recording video" -i screen-recorder \
        "<img src=\"$CACHEFILE\" alt=\"Screenshot\">"\
        --action=open="Open" \
        --action=del="Delete" \
        --action=copy="Copy"
)"
unlink "$CACHEFILE"
case "$reply" in
open) xdg-open "$path" ;;
del) rm "$path" ;;
copy) wl-copy -t text/uri-list "file://$path" ;;
esac
