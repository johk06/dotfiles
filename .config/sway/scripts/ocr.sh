#!/usr/bin/env bash

DATEFMT="%Y_%m.%d_%H:%M:%S"
CACHEDIR="$XDG_CACHE_HOME/ocr"
if [[ ! -d "$CACHEDIR" ]]; then
    mkdir "$CACHEDIR"
fi

function notify {
    response="$(notify-send "Recognized text" "$1" \
        --action=copy="Copy" \
        --action=view="View")"
    case "$response" in
    copy)
        wl-copy <"$2"
        ;;
    view)
        xdg-open "$2"
        ;;
    esac
}

region="$(slurp -w 0 -b '#4c566acc' -s '#ffffff00')"
sleep 0.1

timestamp="$(date +"$DATEFMT")"
imagename="$CACHEDIR/$timestamp.png"
textfile="$CACHEDIR/$timestamp.txt"

if ! grim -g "$region" "$imagename"; then
    exit
fi

available="$(tesseract --list-langs)"
if ! language="$(wayinput -l -1 -t "Language" -c $available)"; then
    exit
fi
language="${language:-eng}"
text="$(tesseract -l "$language" "$imagename" - txt | tee "$textfile" >(wl-copy -p))"

notify "$text" "$textfile"
