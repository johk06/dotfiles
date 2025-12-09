#!/bin/sh

read -r first_line
mimetype="$(
    {
        echo "$first_line"
        cat
    } | file --brief --mime-type -
)"

case "$mimetype" in
text/*)
    text="$first_line"
    lines=$(wc -l)
    ;;
esac

jq -n -c --arg mime "$mimetype" --arg state "$CLIPBOARD_STATE" --arg data "$text" --argjson lines "${lines:-0}" \
    '{data: $data, mime: $mime, state: $state, lines: $lines}' </dev/null
