#!/bin/sh

FILE="$(mktemp)"
SECONDARY="$FILE.copy"
PRIMARY="$FILE.primary"

wl-paste -n -p >"$PRIMARY"
wl-paste -n >"$SECONDARY"

wl-copy -p <"$SECONDARY"
wl-copy <"$PRIMARY"

unlink "$PRIMARY" "$SECONDARY"
