#!/usr/bin/env bash

if pgrep gtklock; then
    systemctl suspend
else
    speak-if-headphones -m "<break time=\"500ms\"/>Attention $USER: Locking Session due to inactivity"
    cd
    gtklock -d
fi
