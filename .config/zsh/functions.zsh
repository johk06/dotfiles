# Utilities {{{
# mainly for use in functions
alias ret="print --"
alias yield="print -l --"
alias fn="function"

# show a nice definition of the command after it
# for functions and aliases, shows the definition
# for builtins and programs, show the full invocation
function getdef {
    {
        whence -w -- "$@"|sed 's/^.*: \(.*\)/\1 /'|tr -d '\n'
        whence -f -x 4 -- "$@"
    } | bat --plain --language zsh
}
compdef getdef=whence

function keys {
    local arrayname="${1}"
    print -l -- ${(@k)${(P)arrayname}}
}
# }}}

# Display {{{
# faster, way faster than proper `clear`
# commonly used for c;command
function c {
    print -n "\e[H\e[2J"
}

function hex2chars {
    printf '0: %s' "$@" | xxd -r
}

function hlcolor {
    while read -r hex; do
        local red=$[ 0x${hex:1:2} ]
        local green=$[ 0x${hex:3:2} ]
        local blue=$[ 0x${hex:5:2} ]
        local avg_bright=$[ (red + green + blue) / 3]

        local foreground=7
        if (( avg_bright > 128 )); then
            foreground=0
        fi
        printf '\e[3%d;48;2;%d;%d;%dm%s\e[0m \e[38;2;%d;%d;%d;m%s\n' \
            $foreground $red $green $blue $hex $red $green $blue $hex
    done
}
# }}}

# Process Utils {{{
# very, very verbose wrapper around `time`
alias jobinfo='TIMEFMT="User:     %U
Kernel:   %S
Time:     %E
Usage:    %P
MemMax:   %MK
Input:    %I
Output:   %O
Recv:     %r
Send:     %s
Signals:  %k
Swaps:    %W
Waits:    %w
Switches: %c"
time'
# }}}

function open {
    local arg
    for arg in "$@"; do
        setsid xdg-open "$arg" >/dev/null 2>&1
    done
}

# generate a "clean" version of the history
# deduplicate
# restore order
function cleanhist {
    fc -l -$HISTSIZE \
        | sort -k 2 | uniq -f 1 \
        | sort -nk 1 | sed 's/^\s*[0-9]*\s*//'
}

source $ZDOTDIR/handlers.zsh

source "$ZDOTDIR/mods/fs.zsh"
source "$ZDOTDIR/mods/fzf.zsh"

if [[ "$TERM" == "xterm-kitty" ]]; then
    source "$ZDOTDIR/mods/kitty.zsh"
fi

if [[ -n "$NVIM" ]]; then
    source "$ZDOTDIR/mods/nvim.zsh"
fi
