#!/usr/bin/bash

CACHEFILE="$XDG_CACHE_HOME/.color_$EPOCHSECONDS.png"

if hash hyprpicker; then
    read -r r g b < <(hyprpicker -r -f rgb)
    if [[ -z "$r" ]]; then
        exit
    fi
else
    # fallback to grim otherwise
    region="$(slurp -b '#00000000' -p)"
    if [[ -z "$region" ]]; then
        exit
    fi
    mapfile ppm < <(grim -g "$region" -t ppm -)

    function byte2int {
        printf -v "$1" "%d" "'$2"
    }

    byte2int r "'${ppm[3]:0:1}"
    byte2int g "'${ppm[3]:1:1}"
    byte2int b "'${ppm[3]:2:1}"
fi

printf -v hex "%02x%02x%02x" $r $g $b

magick -size 90x90 xc:none \
    -fill "#$hex" -draw "circle 40,40 40,0" \
    "$CACHEFILE"

wl-copy -p "#$hex"

reply="$(notify-send "#$hex" -i "$CACHEFILE" \
    --action=rgb="rgb($r, $g, $b)" \
    --action=hex="#$hex")"

case "$reply" in
    rgb) wl-copy "rgb($r, $g, $b)";;
    hex) wl-copy "#$hex";;
esac
unlink "$CACHEFILE"
