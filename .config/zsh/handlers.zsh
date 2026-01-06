function command_not_found_handler {
    # early return if not in tty
    printf "zsh: command not found: '%s'" "$1" >&2
    if [[ ! -t 0 || ! -t 1 ]]; then
        print
        return 127
    fi

    local file="$1"
    local entries=(${(f)"$(pkgfile -b -- "$file")"})
    if (( ${#entries[@]} )); then
        print ", found in:"
        local entry
        { for entry in "${entries[@]}"; do
            (
                local -a fields=(${(s:/:)entry})
                local -a desc
                IFS=$'\n' desc=($(expac -Ss '%d' -- "^${fields[2]}$"))
                print -P "%B%F{magenta}${fields[1]}%f/${fields[2]}%b\t${desc[1]}"
            )&
        done } | column -ts$'\t' >&2
    fi
    return 127
}


function __readnullcommand {
    # HACK: look up related file to guess type correctly
    local realpath="/proc/self/fd/0"
    realpath="${realpath:A}"
    if [[ -f "$realpath" ]]; then
        command bat --color=always -Pp --file-name="$realpath"
    elif [[ -d "$realpath" ]]; then
        command lsd "$realpath"
    fi
}

READNULLCMD=__readnullcommand

function open {
    local arg
    for arg in "$@"; do
        setsid xdg-open "$arg" >/dev/null 2>&1
    done
}

# abuse for the clipboard, can contain any data, not just a dir
function _clipboard_directory_name {
    if [[ "$1" == "d" ]]; then
        return 1
    fi

    if [[ "$1" == "n" ]]; then
        if [[ "$2" != "clip"* ]] && [[ "$2" != "sel"* ]]; then
            return 1
        fi

        local cmd="wl-paste"
        local content err type mime use_mime
        if [[ "$2" == *":"* ]]; then
            IFS=":" read -r type mime <<< "$2"
            use_mime=1
        else
            type="$2"
        fi

        if [[ "$type" == "clip" ]]; then
            if ((use_mime)); then
                local -a mime_types=($(wl-paste -l 2>/dev/null))
                if ! (($mime_types[(Ie)$mime])); then
                    return 1
                fi
                content="$(wl-paste --type "$mime" 2>/dev/null)"
                err=$?
            else
                content="$(wl-paste 2>/dev/null)"
                err=$?
            fi
        elif [[ "$type" == "sel" ]]; then
            if ((use_mime)); then
                local -a mime_types=($(wl-paste --primary -l 2>/dev/null))
                if ! (($mime_types[(Ie)$mime])); then
                    return 1
                fi
                content="$(wl-paste --primary --type "$mime" 2>/dev/null)"
                err=$?
            else
                content="$(wl-paste --primary 2>/dev/null)"
                err=$?
            fi
        fi

        if ((err > 0)) || [[ -z "$content" ]]; then
            return 1
        fi

        typeset -ga reply
        reply=("$content")
        return 0
    fi

    if [[ "$1" == "c" ]]; then
        local primary_types secondary_types primary_err secondary_err
        primary_types=($(wl-paste --primary -l 2>/dev/null))
        primary_err=$?
        secondary_types=($(wl-paste -l 2>/dev/null))
        secondary_err=$?

        local -a compls
        if ! ((primary_err)); then
            compls+=("sel")
            compls+=("${(@)primary_types/#/"sel:"}")
        fi

        if ! ((secondary_err)); then
            compls+=("clip")
            compls+=("${(@)secondary_types/#/"clip:"}")
        fi

        _wanted dynamic-dirs expl 'clipboards' compadd -S\] -a compls
        return
    fi
}

zsh_directory_name_functions+=(_clipboard_directory_name)


# ignore short commands
function _ignore_irrelevant_history {
    local cmd="${1%%$'\n'}"
    cmd="${cmd%%[[:space:]]#}"
    local len=${#cmd}

    # ignore super short commands
    if [[ $len -lt 4 ]]; then
        return 2
    fi

    # don't ignore pipelines
    [[ "$cmd" == *"|"* ]] && return 0

    # ignore short cds
    if [[ ( "$cmd" == "cd"* || "$cmd" == "z"* ) && $len -lt 12 ]]; then
        return 2
    fi
}

zshaddhistory_functions+=(_ignore_irrelevant_history)

# use bat as a pager for man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT='-c'
export PAGER="bat"
