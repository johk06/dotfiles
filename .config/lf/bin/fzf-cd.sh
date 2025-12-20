#!/usr/bin/env bash

res="$(fd -u -t d | fzf --height=999 --prompt="Cd: " --preview='lsd -l {}')"
if [[ "${res:t}" == "."* ]]; then
    lf -remote "send $id set hidden"
fi

printf -v path "%q" "$res"
lf -remote "send $id cd ${path}"
