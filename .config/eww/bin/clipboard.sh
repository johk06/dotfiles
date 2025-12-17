#!/bin/sh

mimetype="$(wl-paste -l | sed 1q)"

case "$mimetype" in
text/*)
    read -r first_line
    text="$first_line"
    lines=$(wc -l)
    ;;
esac

jq -n -c --arg mime "$mimetype" --arg state "$CLIPBOARD_STATE" --arg data "$text" --argjson lines "${lines:-0}" \
    '{data: $data|@json, mime: $mime, state: $state, lines: $lines}' </dev/null
