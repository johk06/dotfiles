#!/usr/bin/env bash

CMD="rg --column --line-number --no-heading --color=always --smart-case"
RELOAD="reload([ -n {q} ] && $CMD -- {q} || true)"
PREVIEW='lnum={2};bat -r$(( lnum < 8 ? 0 : lnum - 8)):$(( lnum + 8 )) --number --color=always --highlight-line={2} -- {1}'

IFS=: read -r fl row col _ < <(fzf --prompt="Select: " \
    --height=100% --ansi --disabled --delimiter=: \
    --bind="start:$RELOAD" \
    --bind="change:$RELOAD" \
    --preview="$PREVIEW")

if [[ "${fl##*/}" == "."* ]]; then
    lf -remote "send $id set hidden"
fi
lf -remote "send $id set user_row \"$row\""

printf -v path "%q" "$fl"
lf -remote "send $id select ${path}"
