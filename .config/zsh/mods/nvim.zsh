# redirect nv inside neovim to nvr
# e.g. `cmd | sp` just opens a split with the results

# all of those functions are necessary since nvr with no arguments
# does not use stdin like neovim
unalias nv
unalias vi
function nv {
    nvr "${@:--}"
}
alias vi=nv

function sp {
    nvr -o "${@:--}"
}

function vsp {
    nvr -O "${@:--}"
}

function tab {
    nvr -p "${@:--}"
}

alias qf="nvr -q -"

# vimgrep
function vg {
    rg --vimgrep "$@" | nvr -q -
}
compdef vg=rg

function getbuf {
    nvr --remote-expr "join(nvim_buf_get_lines($1, ${2:-0}, ${3:--1}, 1), \"\n\")"
}

# make sure the buffer gets closed on q, so that the process exits
ZVM_VI_EDITOR=(nvr -cc Sp -c 'se bufhidden=delete' --remote-wait)
