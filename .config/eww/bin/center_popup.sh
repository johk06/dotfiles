#!/usr/bin/env bash
PIDFILE="/tmp/.eww_popup"
EWW="$XDG_CONFIG_HOME/eww"

declare -A WIDGETS=(
    [audio]=0
    [bright]=1
    [lock]=2
)

if [[ "$1" == close ]]; then
    eww -c "$EWW" update center-popup-reveal=false
    sleep 0.5
    
    if [[ "$(eww -c "$EWW" get center-popup-reveal)" == false ]]; then
        eww -c "$EWW" close center-popup
    fi
    exit
fi

duration="${2:-1}"
widget="${WIDGETS[$1]}"
is_open=0
if [[ "$(eww -c "$EWW" get center-popup-reveal)" == true ]]; then
    is_open=1
fi

if [[ -f "$PIDFILE" ]]; then
    PID="$(< "$PIDFILE")"
    rm -f "$PIDFILE"
    kill "$PID"
fi

echo $$ > "$PIDFILE"

if [[ "$1" == "audio" ]]; then
    eww -c "$EWW" update center-popup-reveal=true audio-popup-kind="$3" center-popup-layer=0
else
    eww -c "$EWW" update center-popup-reveal=true center-popup-layer="$widget"
fi
if ((! is_open)); then
    eww -c "$EWW" open center-popup --screen "$(swaymsg -t get_outputs |jq -r '.[]|select(.focused).name')"
fi

sleep "$duration"

eww -c "$EWW" update center-popup-reveal=false
sleep 0.5
if [[ "$(eww -c "$EWW" get center-popup-reveal)" == false ]]; then
    eww -c "$EWW" close center-popup
fi

rm "$PIDFILE"
