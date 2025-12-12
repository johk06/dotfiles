#!/bin/sh

case "$(playerctl loop)" in
Track) playerctl loop playlist ;;
Playlist) playerctl loop none ;;
None) playerctl loop track ;;
esac
