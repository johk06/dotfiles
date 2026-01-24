#!/usr/bin/env bash

exec rofi -show mute -modes "mute:$XDG_CONFIG_HOME/rofi/applets/mute/mute.sh" \
    -theme "$XDG_CONFIG_HOME/rofi/style/theme.rasi" \
    -config "$XDG_CONFIG_HOME/rofi/applets/mute/config.rasi"
