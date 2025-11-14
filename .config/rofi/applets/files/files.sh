#!/usr/bin/env bash

if ((ROFI_RETV == 0)); then
    fd -I
else
    file="$1"
    case "$file" in
    # HACK: Xournalpp uses regular gzip archives, make sure we treat them specially
    *.xopp)
        xournalpp "$file" >/dev/null 2>&1 &
        ;;
    *)
        xdg-open "$file" >/dev/null 2>&1 &
        ;;
    esac
    disown
fi
