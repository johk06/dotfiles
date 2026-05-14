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

# generate a "clean" version of the history
# deduplicate
# restore order
function cleanhist {
    fc -l -$HISTSIZE \
        | sort -k 2 | uniq -f 1 \
        | sort -nk 1 | sed 's/^\s*[0-9]*\s*//'
}

# search for an option or similar in a man page
function manopt {
    local page="$1"
    local opt="$2"

    local pattern="^\s+$opt|,\s+$opt|\s+$opt"

    LESS="+/$pattern" man "$page"
}

# Intelligently slice input, aliased by @.
function _jhk-less {
    if (($# < 2)); then
        sed "${1:-10}q"
    else
        sed -n "${1},${2}p"
    fi
}

source "$ZDOTDIR/handlers.zsh"

source "$ZDOTDIR/mods/fs.zsh"
source "$ZDOTDIR/mods/fzf.zsh"
source "$ZDOTDIR/mods/zoxide.zsh"

if [[ "$TERM" == "xterm-kitty" ]]; then
    source "$ZDOTDIR/mods/kitty.zsh"
fi

if [[ -n "$NVIM" ]]; then
    source "$ZDOTDIR/mods/nvim.zsh"
fi
