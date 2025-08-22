#!/bin/false

# wrappers around fzf for my most common use cases

if [[ "$1" == "unload" ]]; then
    unfunction fed fcd frg _fzf_shell_hist

    unset FZF_DEFAULT_OPTS
    return
fi

FZF_DEFAULT_OPTS="--pointer='' --no-scrollbar --info=inline-right --no-separator --border=none --preview-border=line --height=~50% --no-bold"
FZF_DEFAULT_OPTS+=" --color="\
prompt:cyan,\
fg:white,\
bg:black,\
bg+:gray,\
gutter:black,\
hl:yellow:underline,\
hl+:yellow:underline,\
info:magenta,\
border:gray,\
query:white:regular,\
preview-fg:white,\
preview-bg:black,\
spinner:cyan,\
marker:magenta,\
header:white

export FZF_DEFAULT_OPTS

# find & edit
function fed {
    local res="$(fd $@ --type=file|fzf --prompt="ed: " --preview='bat -p --color=always -- {}')"
    if [[ -z "$res" ]]; then
        return
    fi
    local parent="${res:h}"
    local abs="${res:A}"
    (cd "$parent"; "$EDITOR" "$abs")
}
compdef fed=fd

# find * cd
function fcd {
    local res="$(fd $@ --type=dir | fzf --prompt="cd: " --preview='lsd -l -- {}')"
    if [[ -n "$res" ]]; then
        cd "$res"
    fi
}
compdef fcd=fd

function _fzf_change_dir {
    fcd
    zle reset-prompt
}

zle -N fzf-change-dir _fzf_change_dir
bindkey "^[c" fzf-change-dir

# search shell history
function _fzf_shell_hist {
    local res="$(fc -n -l $HISTSIZE|awk '!seen[$2]++'|fzf --no-sort --tac --prompt="hist: " -q "^$BUFFER")"
    if [[ -n "$res" ]]; then
        BUFFER="${res}"
        zle end-of-line
    fi
    zle reset-prompt
}
zle -N fzf-shell-hist _fzf_shell_hist
bindkey '^[/' fzf-shell-hist

export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt='cd: ' --preview='lsd -l {2}'"
