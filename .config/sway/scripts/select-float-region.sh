#!/bin/sh

slurp -w 0 -b '#4c566acc' -s '#ffffff00' -f '%x %y %w %h' | {
    read -r x y w h
    swaymsg floating enable';' move absolute position ${x}px ${y}px';' resize set width "$w" height "$h"
}
