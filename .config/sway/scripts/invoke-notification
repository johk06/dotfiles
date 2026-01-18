#!/bin/sh

action="$(wayinput -l 1 --title="Invoke")"
case "$action" in
[0-9])
	swaync-client --action $((action - 1))
	;;
esac
