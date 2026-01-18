#!/bin/sh

pkill -HUP gpg-agent
ssh-add -d

notify-send -i dialog-password -u critical \
    "Reset stored agent passwords" \
    "You will need to enter your password again for gpg and ssh operations"
