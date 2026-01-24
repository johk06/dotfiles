#!/usr/bin/env bash

BOOKMARKS_FILE="$XDG_CONFIG_HOME/rofi/bookmarks.psv"

if ((ROFI_RETV == 0)); then
    fd -I
else
    xdg-open "$1" >/dev/null 2>&1 & disown
fi
