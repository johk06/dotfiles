#!/bin/sh

gamma="$(wayinput -l -1 -t "Temperature [k]" -n)"
if [ -n "$gamma" ]; then
    killall gammastep
    gammastep -O "$gamma"
fi
