# wrappers around fzf for my most common use cases

FZF_DEFAULT_OPTS="--layout=reverse --info=inline-right --preview-border=line --height=~50% --no-bold"
FZF_DEFAULT_OPTS+=" --no-scrollbar --no-separator --border=none --pointer='' --wrap-sign='~' --ellipsis=' ~ '"
FZF_DEFAULT_OPTS+=" --color=prompt:cyan,fg:white,fg+:white,bg:black,bg+:gray,gutter:black,border:gray"
FZF_DEFAULT_OPTS+=",hl:yellow:underline,hl+:yellow:underline,info:magenta,query:white"
FZF_DEFAULT_OPTS+=",preview-fg:white,preview-bg:black,spinner:cyan,marker:magenta,header:white"

export FZF_DEFAULT_OPTS
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt='cd: ' --preview='lsd -l {2}' --no-sort"

function zle-jhk-fzf-complete {
    local tokens=(${(z)LBUFFER})
    local curword
    if [[ ${LBUFFER[-1]} == " " ]]; then
        target=$((${#tokens} + 1))
            curword=""
        else
            target=-1
            curword="${tokens[-1]}"
    fi

    "$1" "$curword"

    if [[ -n "$REPLY" ]]; then
        tokens[$target]="$REPLY"
        LBUFFER="${tokens[@]}"
        zle redisplay
    fi
}

# Cd {{{
function fcd {
    local res="$(fd $@ --type=dir | fzf --prompt="cd: " --preview='lsd -l -- {}')"
    if [[ -n "$res" ]]; then
        cd "$res"
    fi
}
compdef fcd=fd

function zle-jhk-fzf-change-dir {
    fcd
    zle reset-prompt
}

zle -N fzf-change-dir zle-jhk-fzf-change-dir
bindkey "\e " fzf-change-dir
# }}}
# Processes {{{
function fps {
    LIBPROC_HIDE_KERNEL=1 ps -e -o pid= -o comm= -o cmd= |
        fzf -q "$1" --freeze-left=2 --freeze-right=1 --prompt="ps: " --accept-nth=1
}

function zle-jhk-find-proc {
    REPLY="$(fps "$1")"
}

function zle-jhk-complete-proc {
    zle-jhk-fzf-complete zle-jhk-find-proc
}

zle -N fzf-insert-ps zle-jhk-complete-proc
bindkey "\ep" fzf-insert-ps
# }}}
# Paths {{{
function zle-jhk-fzf-files {
    REPLY="$(fd | fzf -q "$1" --prompt="file: " --preview='bat -p --color=always -- {}')"
}

function zle-jhk-complete-path {
    zle-jhk-fzf-complete zle-jhk-fzf-files
}

zle -N fzf-insert-path zle-jhk-complete-path
bindkey "^[f" fzf-insert-path
# }}}
# More powerful C-r {{{
# search shell history
function zle-jhk-fzf-hist {
    local res="$(fc -n -l 1 | awk '!seen[$0]++' | fzf --no-sort --tac --prompt="hist: " -q "$BUFFER")"
    if [[ -n "$res" ]]; then
        BUFFER="${res}"
        zle end-of-line
    fi
    zle reset-prompt
}
zle -N fzf-shell-hist zle-jhk-fzf-hist
bindkey '\er' fzf-shell-hist
bindkey '\e/' fzf-shell-hist
# }}}
