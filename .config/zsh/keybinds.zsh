# Kitty is plenty fast
# NOTE: This makes all multi key chords that do not switch modes basically impossible
# Excluding those builtin like `cc`
KEYTIMEOUT=5

function bindall {
    bindkey -M viins "$@"
    bindkey -M vicmd "$@"
}

# Short Widgets {{{
# Mostly for quick and dirty directory navigation

function jhk-fg-proc {
    if ((${#jobstates} < 1)); then
        zle -M "No running jobs"
        return
    fi

    fg
}
zle -N jhk-fg-proc

function jhk-push-tmp {
    pushd ~tmp >/dev/null 2>&1
    zle reset-prompt
    zle redisplay
}
zle -N jhk-push-tmp
function jhk-push-parent {
    pushd .. >/dev/null 2>&1
    zle reset-prompt
    zle redisplay
}
zle -N jhk-push-parent

function jhk-pop-dir {
    popd >/dev/null 2>&1
    zle reset-prompt
    zle redisplay
}
zle -N jhk-pop-dir

bindall ^Xf jhk-fg-proc
bindall ^Xt jhk-push-tmp
bindall ^Xp jhk-push-parent
bindall ^Xh jhk-pop-dir
# }}}

# Autosuggestions {{{
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
bindall -M viins '^ ' autosuggest-accept
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,bold"
# }}}

# Pairs {{{
source "$ZDOTDIR/pairs.zsh"
# }}}

# Arrow Keys for History {{{
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
bindall "\e[A" up-line-or-beginning-search
bindall "\e[B" down-line-or-beginning-search
# }}}

# Show isearch Status {{{
function zle-isearch-update {
    # display that line, even if we're manually overwriting it
    zle -M " "
    print -nP "%F{8}^%F{magenta}$[HISTCMD - HISTNO]%f cmds ago"
}

function zle-isearch-exit {
    # reset after exit
    zle -M ""
}

zle -N zle-isearch-update
zle -N zle-isearch-exit
# }}}

# Edit in $EDITOR {{{
function jhk-edit-line {
    local tmpfile="$(mktemp "${ZCACHEDIR}/command-XXXX.zsh")"
    <<< "$BUFFER" >! "$tmpfile"

    "$EDITOR" "$tmpfile" </dev/tty
    BUFFER="$(cat "$tmpfile")"
    rm "$tmpfile"
}
zle -N jhk-edit-line
# Open
bindkey -M viins '^O' jhk-edit-line
# }}}

# Keymap Hook {{{
# Set Cursor and KEYTIMEOUT
function zle-keymap-select {
    # Allow exiting insert mode to be fast while keeping the possibility for longer normal mode maps there
    # case "$KEYMAP" in
    #     viins) KEYTIMEOUT=1;;
    #     *) KEYTIMEOUT=100;;
    # esac
    case "$KEYMAP" in
        vicmd) printf '\e[2 q';;
        visual) printf '\e[2 q';;
        *)
            case "$ZLE_STATE" in
                *overwrite*) printf '\e[4 q';;
                *) printf '\e[6 q';;
            esac
            ;;
    esac
}
zle -N zle-keymap-select

# set initial cursor shape when line is opened
function zle-line-init {
    zle-keymap-select
}
zle -N zle-line-init
# }}}

# Additional Textobjects {{{
function map-textobjects {
    local fn="$1"; shift
    autoload -U "$fn"
    zle -N "$fn"
    for mode in visual viopp; do
        for obj in "$@"; do
            bindkey -M "$mode" "a$obj" "$fn"
            bindkey -M "$mode" "i$obj" "$fn"
        done
    done
}

# These files ship with zsh
map-textobjects select-quoted \' \" \`
map-textobjects select-bracketed \
    '(' ')' '[' ']' '{' '}' '<' '>' 'b' 'B'

autoload -U surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround

# shorter, shell-y-er, [q]uote
bindkey -M vicmd q add-surround
bindkey -M vicmd Q change-surround
bindkey -M vicmd s delete-surround # [s]trip
bindkey -M visual q add-surround
# }}}

# Keep majority of Emacs-Style bindings {{{
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^B' backward-char
bindkey -M viins '^F' forward-char
bindkey -M viins '^F' forward-char
# the insert mode compatibility doesn't apply
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^K' kill-line

# History
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^S' history-incremental-search-forward
bindkey -M viins '^P' up-line-or-beginning-search
bindkey -M viins '^N' down-line-or-beginning-search
# }}}

# ^A and ^X from Vim {{{
function jhk-get-cur-word-boundary {
    buffer=$1
    local spos=$CURSOR epos=$CURSOR
    local pattern='[0-9a-zA-Z_]'

    if ! [[ "${buffer:${CURSOR}:1}" =~ $pattern ]]; then
        pattern="[^${pattern:1:-1} ]"
    fi

    for ((; $spos >= 0; spos--)); do
        [[ "${buffer:${spos}:1}" =~ $pattern ]] || break
    done
    for ((; $epos < $#buffer; epos++)); do
        [[ "${buffer:${epos}:1}" =~ $pattern ]] || break
    done

    ((spos++))
    reply=($spos $epos)
}
function jhk-change-value {
    jhk-get-cur-word-boundary "$BUFFER"
    local start=${reply[1]}
    local end=${reply[2]}
    if [[ $start != 0 && ${BUFFER:$((start-1)):1} == [+-] ]]; then
        ((start --))
    fi

    if ((start >= end)); then
        return
    fi

    local len=$((end - start))
    local word=${BUFFER:${start}:${len}}
    local replacement

    local count=${NUMERIC:-1}
    local inc=0
    if [[ "$KEYS" == $'\x01' ]]; then
        inc=1
    fi

    if [[ "$word" =~ '^[0-9]+$'
        || "$word" =~ '^0x[0-9a-fA-F]+$'
        || "$word" =~ '^0b[01]+$' ]]; then
        local as_num=$(($word))
        local base=10 prefix=""

        if [[ "$word" == "0x"* ]]; then
            base=16
            prefix=0x
        elif [[ "$word" == "0b"* ]]; then
            base=2
            prefix=0b
        fi

        local changed_num
        if ((inc)); then
            changed_num=$((as_num + count))
        else
            if [[ $base != 10 ]]; then
                # Don't allow decrementing anything but base 10 down past 0
                changed_num=$((as_num == 0 ? 0 : as_num - count))
            else
                changed_num=$((as_num - count))
            fi
        fi
        eval replacement='${prefix}$(( [##${base}] changed_num))'
    else
        replacement=$word
    fi

    BUFFER="${BUFFER:0:$start}$replacement${BUFFER:$end}"
}

zle -N jhk-change-value
bindkey -M vicmd ^A jhk-change-value
bindkey -M vicmd ^X jhk-change-value
# }}}

# Keep line but still run the command
bindall "\e^M" accept-and-hold
# Like "suspending" the current command
bindall '^Z' push-input

# Don't delete as much with C-w
WORDCHARS="*?_.[]~=!#$%^(){}"

# TODO: Unused and easy to reach keymaps:
# ^T
# ^Y
# basically all of the meta-keys
