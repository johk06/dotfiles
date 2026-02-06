# wrappers around fzf for my most common use cases

FZF_DEFAULT_OPTS="--layout=reverse --info=inline-right --preview-border=line --height=~50% --no-bold"
FZF_DEFAULT_OPTS+=" --no-scrollbar --no-separator --border=none --pointer='' --wrap-sign='~' --ellipsis=' ~ '"
FZF_DEFAULT_OPTS+=" --color=prompt:cyan,fg:white,bg:black,bg+:gray,gutter:black,border:gray"
FZF_DEFAULT_OPTS+=",hl:yellow:underline,hl+:yellow:underline,info:magenta,query:white"
FZF_DEFAULT_OPTS+=",preview-fg:white,preview-bg:black,spinner:cyan,marker:magenta,header:white"

export FZF_DEFAULT_OPTS
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --prompt='cd: ' --preview='lsd -l {2}' --no-sort"

# Cd {{{
function fcd {
    local res="$(fd $@ --type=dir | fzf --prompt="cd: " --preview='lsd -l -- {}')"
    if [[ -n "$res" ]]; then
        cd "$res"
    fi
}
compdef fcd=fd

function _fzf_do_completion {
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

function _fzf_change_dir {
    fcd
    zle reset-prompt
}

zle -N fzf-change-dir _fzf_change_dir
bindkey "\e " fzf-change-dir
# }}}

# Processes {{{
function fps {
    LIBPROC_HIDE_KERNEL=1 ps -e -o pid= -o comm= -o cmd= |
        fzf -q "$1" --freeze-left=2 --freeze-right=1 --prompt="ps: " --accept-nth=1
}

function _fzf_find_ps {
    REPLY="$(fps "$1")"
}

function _fzf_complete_ps {
    _fzf_do_completion _fzf_find_ps
}

zle -N fzf-insert-ps _fzf_complete_ps
bindkey "\ep" fzf-insert-ps
# }}}

# Paths {{{
function _fzf_find_path {
    REPLY="$(fd | fzf -q "$1" --prompt="file: " --preview='bat -p --color=always -- {}')"
}

function _fzf_complete_path {
    _fzf_do_completion _fzf_find_path
}

zle -N fzf-insert-path _fzf_complete_path
bindkey "^[f" fzf-insert-path
# }}}

# More powerful C-r {{{
# search shell history
function _fzf_shell_hist {
    local res="$(fc -n -l 1 | awk '!seen[$0]++' | fzf --no-sort --tac --prompt="hist: " -q "$BUFFER")"
    if [[ -n "$res" ]]; then
        BUFFER="${res}"
        zle end-of-line
    fi
    zle reset-prompt
}
zle -N fzf-shell-hist _fzf_shell_hist
bindkey '\er' fzf-shell-hist
bindkey '\e/' fzf-shell-hist
# }}}
