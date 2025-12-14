#!/usr/bin/env bash

ICON="\0icon\x1f"
SET_DELIM="\0delim\x1f"

print_walls() {
    for file in "$XDG_CONFIG_HOME"/background/img/*; do
        name="${file##*/}"
        printf "%s$ICON%s\t" "$name" "$file"
    done
}

if ((ROFI_RETV != 0)); then
    wallpaper both "$XDG_CONFIG_HOME/background/img/$1" >/dev/null 2>&1
    echo -en "$SETSEL$ROFI_INFO"
else
    echo -en "$SET_DELIM\t\n"
fi
echo -en "\0keep-selection\x1ftrue\t"

print_walls
