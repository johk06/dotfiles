#!/usr/bin/env bash

NAME="$1"
SUBPATH="$2"
IP="$3"
PORT="$4"
PASS="$5"

DIR="$HOME/Tmp/mount"
mkdir -p "$DIR"
TARGET="$DIR/$NAME"
if [[ -d "$TARGET" ]]; then
    xdg-open "$TARGET"
else
    mkdir -p "$TARGET"
    (
        unset DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_ASKPASS_REQUIRE
        echo "$PASS" | sshfs -o StrictHostKeyChecking=no -o password_stdin -p "$PORT" "kdeconnect@$IP:$SUBPATH" "$TARGET"
    )
fi
