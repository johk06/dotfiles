#!/bin/false
# vim: ft=zsh

# make filesystem naviation/file handling easier

if [[ "$1" == "unload" ]]; then

    unfunction rgf mcd rp bn rcd \
        pwf \
        root

    unalias md ft bft zcp zln

    unfunction zmv

    return
fi

alias md="mkdir -p"

function mcd {
    if [[ ! -d "$1" ]] {
        mkdir -p "$1"
    }
    cd "$1"
}
compdef mcd=mkdir


alias ft="file --mime-type -F$'\t'"
alias bft="file --brief --mime-type -N"

# better realpath
function rp {
    print -l -- "${@:A}"
}
# basename
function bn {
    print -l -- "${@:t}"
}

# list recursive
function lr {
    command lsd --tree --depth 3 --hyperlink=always "$@" | less -rFi
}

# list hierarchy
function lh {
    command lsd --tree --directory-only --hyperlink=always "$@" | less -rFi
}

# like pwd but takes into account all the shell magic
function pwf {
    print -P -- "%~"
}

# go up n levels; in a subshell, return the absolute path to the directory n levels above
function .. {
    local level="$1"
    if [[ -t 1 ]] {
        if [[ ! "$level" =~ '[0-9]+' ]] {
            cd ..
            return
        }

        local fmt
        printf -v fmt "../%.0s" {1..$level}
        cd "$fmt"
    } else {
        local fmt
        printf -v fmt "../%.0s" {1..$level}
        print -- "${fmt:a}"
    }
}

# find the parent directory containing a file or dir
# e.g. `root .git` or `root compile_commands.json`
# if further arguments are given, it evaluates the rest in that place
# otherwise cd to that directory
function root {
    local pattern="$1"
    local cwd="$PWD"
    local root

    while [[ "$cwd" != "" && ! -e "$cwd/$pattern" ]]; do
        cwd="${cwd%/*}"
    done

    if [[ "$cwd" == "" ]]; then
        if [[ -e "/$pattern" ]]; then
            root="/"
        else
            root="."
        fi
    else
        root="$cwd"
    fi

    if [[ $# -gt 1 ]]; then
        (cd "$root"; eval "${@:2}")
    else
        cd "$root"
    fi
}

# list files found using fd expression
function lfd {
    fd "$@" --exec-batch lsd --directory-only -l -- '{}'
}
compdef lfd=fd

autoload -Uz zmv
alias zcp="zmv -C" zln="zmv -p 'ln -s'"
