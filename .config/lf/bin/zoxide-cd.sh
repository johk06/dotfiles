#!/usr/bin/env bash

result="$(_ZO_FZF_OPTS="$_ZO_FZF_OPTS --height=999" zoxide query -i)"
printf -v path "%q" "$result"
lf -remote "send $id cd ${path}"
