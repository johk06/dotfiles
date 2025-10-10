#!/bin/sh

exec rofi -show files\
    -modes "files:$XDG_CONFIG_HOME/rofi/applets/files/files.sh"\
    -theme "$XDG_CONFIG_HOME/rofi/applets/files/theme.rasi"
