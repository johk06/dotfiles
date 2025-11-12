#!/bin/sh

FILE="$(mktemp)"
SECONDARY="$FILE.copy"
PRIMARY="$FILE.primary"

wl-paste -p >"$PRIMARY"
wl-paste >"$SECONDARY"

wl-copy -p <"$SECONDARY"
wl-copy <"$PRIMARY"

unlink "$PRIMARY" "$SECONDARY"
