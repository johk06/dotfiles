#!/bin/bash

function set_walls() {
    if ! swww query; then
        swww-daemon &
        sleep 1
    fi
    swww img -t grow \
        --transition-pos bottom \
        --transition-duration 1.2 \
        --transition-fps 60 \
        "$HOME/.config/background/wall"
}
function set_as_wall() {
    unlink "$HOME/.config/background/wall"
    ln -s "$1" "$HOME/.config/background/wall"
}

function set_as_lock() {
    unlink "$HOME/.config/background/lock"
    ln -s "$1" "$HOME/.config/background/lock"
}
case $1 in
lock)
    set_as_lock "$2"
    ;;
wall)
    set_as_wall "$2"
    set_walls
    ;;
both)
    set_as_wall "$2"
    set_as_lock "$2"
    set_walls
    ;;
set)
    set_walls
    ;;
esac
