#!/usr/bin/env bash

if pgrep gtklock; then
    systemctl suspend
else
    cd
    gtklock -d
fi
