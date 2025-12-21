#!/usr/bin/env bash

res="$(fd -u|fzf --height=999 --prompt="Select: ")"
if [[ "${res##*/}" == "."* ]]; then
    lf -remote "send $id set hidden"
fi

printf -v path "%q" "$res"
lf -remote "send $id select ${path}"
