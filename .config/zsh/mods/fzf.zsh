# wrappers around fzf for my most common use cases

FZF_DEFAULT_OPTS="--pointer='' --no-scrollbar --info=inline-right --no-separator --border=none --preview-border=line --height=~50% --no-bold"
FZF_DEFAULT_OPTS+=" --color="prompt:cyan,fg:white,bg:black,bg+:gray,gutter:black,hl:yellow:underline,hl+:yellow:underline,info:magenta,border:gray,query:white:regular,preview-fg:white,preview-bg:black,spinner:cyan,marker:magenta,header:white

export FZF_DEFAULT_OPTS

# find * cd
function fcd {
    local res="$(fd $@ --type=dir | fzf --prompt="cd: " --preview='lsd -l -- {}')"
    if [[ -n "$res" ]]; then
        cd "$res"
    fi
}
compdef fcd=fd

function _fzf_change_dir {
    cd/
    zle reset-prompt
}

zle -N fzf-change-dir _fzf_change_dir
bindkey "^[c" fzf-change-dir

function _fzf_insert_path {
    local res="$(fd $@ | fzf --prompt="file: " --preview='bat -p --color=always -- {}')"
    if [[ -n "$res" ]]; then
        LBUFFER+="${res:q}"
        zle redisplay
    fi
}
zle -N fzf-insert-path _fzf_insert_path
bindkey "^[f" fzf-insert-path

# search shell history
function _fzf_shell_hist {
    local res="$(fc -n -l $HISTSIZE | awk '!seen[$2]++' | fzf --no-sort --tac --prompt="hist: " -q "^$BUFFER")"
    if [[ -n "$res" ]]; then
        BUFFER="${res}"
        zle end-of-line
    fi
    zle reset-prompt
}
zle -N fzf-shell-hist _fzf_shell_hist
bindkey '^[/' fzf-shell-hist

export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt='cd: ' --preview='lsd -l {2}' --no-sort"
