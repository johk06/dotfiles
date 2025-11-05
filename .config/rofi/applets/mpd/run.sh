#!/bin/sh

exec rofi -show queue \
    -modes "queue:$XDG_CONFIG_HOME/rofi/applets/mpd/select-in-queue"\
    -theme "$XDG_CONFIG_HOME/rofi/style/list-plain.rasi"
