#!/usr/bin/env bash

function escape {
    sed -z 's/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g;s/^/"/;s/$/"/'
}
function aescape {
    printf '%s\n' "$@" | jq --raw-input -rj '@sh, " "'
}

function run_in_tty {
    lf -remote "send $id \${{ $(aescape "$@") }}"
}

dir="$1"
what="$2"
shift 2

case "$what" in
edit)
    if [[ -e "$NVIM" ]]; then
        case "$dir" in
        vsp)
            arg=-O
            ;;
        sp)
            arg=-o
            ;;
        esac

        nvr $arg "$@"
    elif [[ "$TERM" == "xterm-kitty" ]]; then
        case "$dir" in
        vsp)
            location=vsplit
            ;;
        sp)
            location=hsplit
            ;;
        none)
            run_in_tty nvim "$fx"
            exit
            ;;
        esac

        escaped="$(aescape "$fx")"
        kitty @ launch --copy-env --cwd="$PWD" --type=window --location="$location" zsh -ic -- "nvim $escaped"
    fi
    ;;
shell)
    if [[ -e "$NVIM" ]]; then
        case "$dir" in
        vsp)
            cmd="vertical new"
            ;;
        sp)
            cmd="new"
            ;;
        *)
            cmd="enew"
            ;;
        esac

        nvr -c "lcd $*" -c "$cmd" -c "terminal"
    elif [[ "$TERM" == "xterm-kitty" ]]; then
        case "$dir" in
        vsp)
            location=vsplit
            ;;
        sp)
            location=hsplit
            ;;
        none)
            run_in_tty zsh
            exit
            ;;
        esac

        escaped="$(aescape "$fx")"
        kitty @ launch --copy-env --type=window --location="$location" --cwd="$*" zsh
    fi
    ;;
lf)
    if [[ -e "$NVIM" ]]; then
        case "$dir" in
        vsp)
            cmd="vertical new"
            ;;
        sp)
            cmd="new"
            ;;
        *)
            cmd="enew"
            ;;
        esac

        nvr -c "lcd $*" -c "$cmd" -c "terminal lf"
    elif [[ "$TERM" == "xterm-kitty" ]]; then
        case "$dir" in
        vsp)
            location=vsplit
            ;;
        sp)
            location=hsplit
            ;;
        none)
            run_in_tty lf
            exit
            ;;
        esac

        escaped="$(aescape "$fx")"
        kitty @ launch --copy-env --cwd="$*" --type=window --location="$location" zsh -ic "lf"
    fi
    ;;
esac
