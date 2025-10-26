#!/bin/false
# vim: ft=zsh

if [[ "$1" == "unload" ]]; then
    unalias sparse-clone sparse-add unstage

    unset GH

    return
fi

alias sparse-clone="git clone --filter=blob:none --sparse" \
    sparse-add="git sparse-checkout add"\
    unstage="git restore --staged -- "

GH="https://github.com"
GHSSH="git@github.com"
