#!/usr/bin/env bash

target="$(wayinput -l -1 -t "Language(s)")"
declare -a args
if [[ -n "$target" ]]; then
    read -r language rest <<< "$target"
    IFS=":" read -r dest source <<< "$language"
    if [[ -n "$source" ]]; then args+=("-s$source"); fi
    if [[ -n "$dest" ]]; then args+=("-t$dest"); fi

    for extra in $rest; do
        args+=("$extra")
    done
fi


wl-paste $1 | translate -p "${args[@]}" | {
    read -r header
    read -r -d '' content
    response="$(notify-send -i config-language \
        "$header" \
        "$content" \
        --action=copy="Copy" \
        --action=view="View")"
    case "$response" in
    copy) echo "$content" | wl-copy ;;
    view)
        tmpfile="$(mktemp)"
        echo "$content" >"$tmpfile"
        xdg-open "$tmpfile"
        ;;
    esac
}
