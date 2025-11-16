#!/bin/sh

if [ -n "$1" ]; then
    eww update weather-city="$1" weather="$(curl -rf "wttr.in/$1?format=j1")"
else
    CITY="$(eww get weather-city)"
    curl -sf "wttr.in/$CITY?format=j1"
fi
