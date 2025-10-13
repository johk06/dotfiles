#!/usr/bin/env bash

if ! out="$(yad --form --field=Track --field=Artist --field=Album --field=Genre --field=Shuffle:CHK --field=Append:CHK \
    '' '' '' '' 'TRUE' 'FALSE' --buttons-layout=edge --button=Play:0 --button=Abort:1)"; then
    exit
fi

IFS="|" read -r track artist album genre shuffle append <<<"$out"
if [[ "$append" != "TRUE" ]]; then
    mpc clear
fi
mpc search title "$track" artist "$artist" album "$album" genre "$genre" | mpc add
playerctl stop
if [[ "$shuffle" == TRUE ]]; then
    mpc shuffle
fi
mpc play
