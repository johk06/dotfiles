#!/usr/bin/env bash

list_files() {
    fd --no-ignore-vcs $@
}

open_file() {
    case "$1" in
    # HACK: Xournalpp uses regular gzip archives, make sure we treat them specially
    *.xopp)
        xournalpp "$1" >/dev/null 2>&1 &
        ;;
    *)
        xdg-open "$1" >/dev/null 2>&1 &
        ;;
    esac
    disown
}

parse_flags() {
    FLAGS="$ROFI_DATA"
    for flag in "$@"; do
        case "$flag" in
        \.*)
            FLAGS="$FLAGS -e ${flag:1}"
            ;;
        =*)
            FLAGS="$FLAGS -t ${flag:1}"
            ;;
        !*)
            FLAGS="$FLAGS -E ${flag:1}"
            ;;
        @*)
            FLAGS="$FLAGS --changed-within ${flag:1}"
            ;;
        '>'*)
            FLAGS="$FLAGS --changed-after ${flag:1}"
            ;;
        '<'*)
            FLAGS="$FLAGS --changed-before ${flag:1}"
            ;;
        *)
            FLAGS="$FLAGS ${flag}"
            ;;
        esac
    done
    printf '\0prompt\x1f%s\n' "$FLAGS"
}

if ((ROFI_RETV == 0)); then
    printf '\0use-hot-keys\x1ftrue\n'
    printf '\0prompt\x1f[]\n'
    list_files ""
else
    case "$ROFI_RETV" in
    1)
        open_file "$1"
        ;;
    2)
        parse_flags $1
        printf '\0data\x1f%s\n' "$FLAGS"
        list_files $FLAGS
        ;;
    esac
fi
