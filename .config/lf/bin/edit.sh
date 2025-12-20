#!/usr/bin/env bash

dir="$1"
shift

if [[ -e "$NVIM" ]]; then
    case "$dir" in
    vsp)
        arg=-O
        ;;
    sp)
        arg=-o
        ;;
    esac

    nvr "$arg" "$@"
elif [[ "$TERM" == "xterm-kitty" ]]; then
    case "$dir" in
    vsp)
        location=vsplit
        ;;
    sp)
        location=split
        ;;
    esac
    eval-in-split "$location" 50 "nvim" "$@"
fi
