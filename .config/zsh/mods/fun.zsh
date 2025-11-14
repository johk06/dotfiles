#!/bin/false
# vim: ft=zsh

# functional patterns in zsh

if [[ "$1" == "unload" ]]; then

    unfunction filter tfilter ffilter \
        map cmap vmap cvmap fmap \
        fold vfold afold \
        interlace \
        keys \
        getdef

    unalias fn '\\' 'λ' ret yield
    return
fi

# all of these work pretty much the same:
# argv will be set based on an element in either an array or a line in stdin, split based on IFS
# use "$*" if you want to access it all like one variable

function map {
    local expr="$1"; shift
    local arg

    if (($# == 0)); then
        while read -r arg; do
            argv=(${=arg})
            eval $expr
        done
    else
        for arg in "$@"; do
            argv=(${=arg})
            eval $expr
        done
    fi
}


# first param is a function name
function fmap {
    local func="$1"; shift
    if (($# == 0)); then
        while read -r arg; do
            "$func" "${=arg}"
        done
    else
        for arg in "$@"; do
            "$func" "${=arg}"
        done
    fi
}

# conditional map, basically tfilter|map
function cmap {
    local cmp="[[ $1 ]]" 
    local expr="$2" 
    shift 2
    local arg

    if (($# == 0)); then
        while read -r arg; do
            argv=(${=arg})
            if eval $cmp; then
                eval $expr
            fi

        done
    else
        for arg in "$@"; do
            argv=(${=arg})
            if eval $cmp; then
                eval $expr
            fi
        done
    fi
}

# variable map
# syntax sugar, for e.g ${*:A} for realpath
function vmap {
    local expr="print -- $1"; shift
    map "$expr" "$@"
}

function cvmap {
    local cmp="$1"
    local expr="print -- $2"
    shift 2
    cmap "$cmp" "$expr" "$@"
}


# for each input, run expr, passing the accumulator as $acc, then print the accumulator
function fold {
    local expr="$1"; shift
    local arg
    local accumulator=""

    if (($# == 0)); then
        while read -r arg; do
            argv=(${=arg})
            local acc="$accumulator"
            accumulator="$(eval "$expr")"
        done
    else
        for arg in "$@"; do
            argv=(${=arg})
            local acc="$accumulator"
            accumulator="$(eval "$expr")"
        done
    fi

    print -- "$accumulator"
}

# same as vmap etc
function vfold {
    local expr="print -- $1"
    shift 1
    fold "$expr" "$@"
}

# for numbers specifically
function afold {
    local expr="print -- \$[ "$1" ]"
    shift 1
    fold "$expr" "$@"
}

# only return values for with $expr returns 0
function filter {
    local expr="$1"; shift
    local arg

    if (($# == 0)); then
        while read -r arg; do
            argv=(${=arg})
            if eval $expr; then
                print -- $arg
            fi
        done
    else
        for arg in "$@"; do
            argv=(${=arg})
            if eval $expr; then
                print -- $arg
            fi
        done
    fi
}

# takes in a function e.g
# fn isFile { [[ -f "$*" ]]}
# ffilter isFile *
function ffilter {
    local func="$1"; shift
    local arg

    if (($# == 0)); then
        while read -r arg; do
            if "$func" "${=arg}"; then
                print -- "$arg"
            fi
        done
    else
        for arg in "$@"; do
            if "$func" "${=arg}"; then
                print -- "$arg"
            fi
        done
    fi
}

# syntax sugar to use expressions like test or [[ ]]
# e.g. tfilter '-f "$*"' *
function tfilter {
    local expr="[[ $1 ]]"; shift
    local arg

    if (($# == 0)); then
        while read -r arg; do
            argv=(${=arg})
            if eval $expr; then
                print -- $arg
            fi
        done
    else
        for arg in "$@"; do
            argv=(${=arg})
            if eval $expr; then
                print -- $arg
            fi
        done
    fi
}

# join every $1 lines together with $2
function interlace {
    local numcols="${1:-2}"
    local sep="${2:-' '}"

    local -a buf
    local count=1

    while read -r line; do
        buf[$[count++]]="$line"

        if ((count == numcols+1)); then
            print "${(pj[$sep])buf}"
            count=1
            buf=()
        fi
    done
}

# nicer to type
alias fn="function" '\\'="function" 'λ'="function"

# mainly for use in functions
alias ret="print --"
alias yield="print -l --"

# show a nice definition of the command after it
# for functions and aliases, shows the definition
# for builtins and programs, show the full invocation
function getdef {
    IFS=': ' read -r _ type < <(whence -w -- "$1")
    (
        whence -w -- "$@"|sed 's/^.*: \(.*\)/\1 /'|tr -d '\n'
        whence -f -x 4 -- "$@"
    ) | bat --plain --language zsh
}

compdef getdef=whence



function keys {
    local arrayname="${1}"
    print -l -- ${(@k)${(P)arrayname}}
}
