#!/bin/false
# vim: ft=zsh

if [[ "$1" == "unload" ]]; then
    unfunction procmem proccmd
    unalias jobinfo

    return
fi

# very, very verbose wrapper around `time`
alias jobinfo='TIMEFMT="User:     %U
Kernel:   %S
Time:     %E
Usage:    %P
MemMax:   %MK
Input:    %I
Output:   %O
Recv:     %r
Send:     %s
Signals:  %k
Swaps:    %W
Waits:    %w
Switches: %c"
time'
