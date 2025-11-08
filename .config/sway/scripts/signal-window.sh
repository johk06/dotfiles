#!/bin/sh

SIGNALS="HUP INT QUIT ILL TRAP IOT BUS FPE KILL USR1 SEGV USR2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU URG XCPU XFSZ VTALRM PROF WINCH POLL PWR SYS"

pid="$(swaymsg -t get_tree | jq -r '.. | ((.nodes? // empty), (.floating_nodes? // empty))[] | select(.focused).pid')"
signal="$(wayinput -t "Signal" -l -1 -c $SIGNALS)"
if [ -z "$signal" ]; then
    exit
fi

kill -"$signal" "$pid"
