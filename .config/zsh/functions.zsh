# faster, way faster than proper `clear`
function c {
    print -n "\e[H\e[2J"
}

# run program in alternate screen
function @alt {
    if [[ -t 1 ]]; then
        tput smcup
        eval "$@"
        tput rmcup
    fi
}

compdef @alt=eval

function chars2codes {
    local char
    while read -u0 -k1 -r char; do
        printf "%02x\n" "'$char"
    done
}

function codes2chars {
    local code
    while read -r code; do
        printf "\\U$code"
    done
}

function hex2chars {
    printf '0: %s' "$@" | xxd -r
}

function lcd {
    cd "$(command lf -print-last-dir "$@")"
}

# simple clone of the tool with the same name
function vipe {
    local tmpfile="$(mktemp)"
    cat >> "$tmpfile"
    if [[ -n "$1" && "$EDITOR" == *vim ]]; then
        $EDITOR "$tmpfile" +"setf $1" > /dev/tty < /dev/tty
    else
        $EDITOR "$tmpfile" > /dev/tty < /dev/tty
    fi
    cat "$tmpfile"
    command rm -rf "$tmpfile"
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

# load all the modules i always want
source "$ZDOTDIR/mods/fun.zsh"
source "$ZDOTDIR/mods/proc.zsh"
source "$ZDOTDIR/mods/net.zsh"
source "$ZDOTDIR/mods/fs.zsh"
source "$ZDOTDIR/mods/structured_data.zsh"
source "$ZDOTDIR/mods/git.zsh"
source "$ZDOTDIR/mods/fzf.zsh"

if [[ "$TERM" == "xterm-kitty" ]]; then
    source "$ZDOTDIR/mods/kitty.zsh"
fi
