#!/usr/bin/env zsh
IFS=$'\n'

local files=(${=fx})
files=(${files:t})

printf '%s\n' "$files" | eval "$@" | paste -d "\n" - <(<<<"$files") |
    while read -r new_name; do
        read -r old_name
        if [[ "$new_name" == "$old_name" ]]; then
            continue
        fi

        if [[ -e "$new_name" ]]; then
            lf -remote "send $id echoerr File exists: ${(q)new_name}"
            continue
        fi

        mv "$old_name" "$new_name"
    done
