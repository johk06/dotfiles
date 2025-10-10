#!/bin/sh

exec rofi -show pass\
    -modes "pass:$XDG_CONFIG_HOME/rofi/applets/pass/pass.sh"
