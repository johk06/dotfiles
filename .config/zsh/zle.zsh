# My custom zle widgets & Tweaks to the zle
# NOTE: This makes all multi key chords that do not switch modes basically impossible
# Excluding those builtin like `cc`
KEYTIMEOUT=5

# Mapping for insert and normal mode
function bindall {
    bindkey -M viins "$@"
    bindkey -M vicmd "$@"
}

# Short Widgets {{{
# Quickly manipulate the shell state

# FIXME: if the command overflows the screen, we cannot do anything,
# just C-l in that case
function jhk-zle-below-prompt {
    zle -M ""
    echotc sc
    eval "$@"
    echotc rc
}

# Foreground the current background job
function zle-jhk-fg-proc {
    if ((${#jobstates} < 1)); then
        zle -M "No running jobs"
        return
    fi

    fg
}; zle -N zle-jhk-fg-proc

# Push the temp directory
function zle-jhk-push-tmp {
    pushd ~tmp >/dev/null 2>&1
    precmd
    zle reset-prompt
}; zle -N zle-jhk-push-tmp

# Push the parent
function zle-jhk-push-parent {
    pushd .. >/dev/null 2>&1
    precmd
    zle reset-prompt
}; zle -N zle-jhk-push-parent

# Return down the directory stack
function zle-jhk-pop-dir {
    if ! popd >/dev/null 2>&1; then
        zle -M "Directory stack is empty"
    else
        precmd
        zle reset-prompt
    fi
}; zle -N zle-jhk-pop-dir

# Like run-help, but show help for an option
function zle-jhk-opt-run-help {
    local cmd=(${(z)${LBUFFER}})

    local -a command
    local option
    for ((i=(${#cmd}); i > 0; i--)); do
        local arg=${cmd[$i]}
        if [[ "$arg" == "|"
            || "$arg" == ";"
            || "$arg" == "&&"
            || "$arg" == "&"
            || "$arg" == "||" ]]; then
            break
        fi

        case "$arg" in
            -*) if [[ -z "$option" ]]; then
                option="$arg"
                fi;;
            *) command+=("$arg");;
        esac
    done

    local program
    case "${command[-1]}" in
        ssh) program="${command[-3]}";;
        sudo) program="${command[-2]}";;
        *) program="${command[-1]}"
    esac

    if [[ -n "$program" && -n "$option" ]]; then
        manopt "$program" "$option" 2>/dev/null
        if [[ $? != 0 ]]; then
            zle -M "Failed to get manpage for $program"
        fi
    fi
}; zle -N zle-jhk-opt-run-help

function zle-jhk-ls {
    jhk-zle-below-prompt lsd
}; zle -N zle-jhk-ls

function zle-jhk-ls-detailed {
    jhk-zle-below-prompt lsd -l
}; zle -N zle-jhk-ls-detailed

function zle-jhk-lschg {
    jhk-zle-below-prompt lschg
}; zle -N zle-jhk-lschg

# Run a single command below the prompt
autoload -U read-from-minibuffer
function zle-jhk-run-below {
    local oldbuf="$BUFFER"
    read-from-minibuffer "_ "
    jhk-zle-below-prompt "$REPLY"
    BUFFER="$oldbuf"
}; zle -N zle-jhk-run-below

bindall ^Xf zle-jhk-fg-proc
bindall ^Xt zle-jhk-push-tmp
bindall ^Xp zle-jhk-push-parent
bindall ^Xo zle-jhk-pop-dir
bindall ^Xm zle-jhk-opt-run-help
bindall ^Xl zle-jhk-ls
bindall ^XL zle-jhk-ls-detailed
bindall ^Xg zle-jhk-lschg
bindall ^Xr zle-jhk-run-below
# }}}
# Autosuggestions {{{
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
bindall -M viins '^ ' autosuggest-accept
# }}}
# Pairs {{{
source "$ZDOTDIR/pairs.zsh"
# }}}
# Arrow Keys for History {{{
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
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
function zle-jhk-edit-line {
    local tmpfile="$(mktemp "${ZCACHEDIR}/command-XXXX.zsh")"
    <<< "$BUFFER" >! "$tmpfile"

    "$EDITOR" "$tmpfile" </dev/tty
    BUFFER="$(cat "$tmpfile")"
    rm "$tmpfile"
}
zle -N zle-jhk-edit-line
# Open
bindkey -M viins '^O' zle-jhk-edit-line
bindkey -M vicmd 'ze' zle-jhk-edit-line
# }}}
# Set Cursor based on mode {{{
function zle-keymap-select {
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

# NOTE: I cannot use ys & c due to the $KEYTIMEOUT but this is shorter anyways
bindkey -M vicmd  q add-surround    # [q]uote
bindkey -M visual q add-surround
bindkey -M vicmd  Q change-surround
bindkey -M vicmd  s delete-surround # [s]trip
# }}}
# Keep majority of Emacs-Style bindings {{{
bindkey -M viins \
    '^A' beginning-of-line \
    '\e[H' beginning-of-line \
    '^E' end-of-line \
    '\e[F' end-of-line
bindkey -M viins \
    '^B' backward-char \
    '^F' forward-char

# the insert mode compatibility doesn't apply, I *do* want to backspace over the start of insert mode
bindkey -M viins \
    '^W' backward-kill-word \
    '^U' backward-kill-line \
    '^K' kill-line

# History
bindkey -M viins \
    '^R' history-incremental-search-backward \
    '^S' history-incremental-search-forward \
    '^P' up-line-or-beginning-search \
    '^N' down-line-or-beginning-search

# }}}

# Quite useful to insert an additional argument
function zle-jhk-almost-beginning-of-line {
    zle beginning-of-line
    zle vi-forward-blank-word-end
    zle vi-forward-char
}
zle -N zle-jhk-almost-beginning-of-line
bindall '\ea' zle-jhk-almost-beginning-of-line

# Get the arguments of the previous command
function zle-jhk-insert-last-cmdline {
    zle insert-last-word -- -1 ${NUMERIC:-2} 1
    zle zle-jhk-almost-beginning-of-line
    LBUFFER="$LBUFFER "
}
zle -N zle-jhk-insert-last-cmdline
bindall '^T' zle-jhk-insert-last-cmdline

# Keep line but still run the command
bindall "\e^M" accept-and-hold
# Like "suspending" the current commandline
bindall '^Z' push-input

# Don't delete as much with C-w
WORDCHARS="*?_.[]~=!#$%^(){}"

# TODO: Unused and easy to reach keymaps:
# ^Y
# basically all of the meta-keys
