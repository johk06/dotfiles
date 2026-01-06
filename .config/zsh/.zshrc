# load the initial time first so we can show it in the prompt
zmodload zsh/datetime
_PROMPTTIMER=$EPOCHREALTIME

ZCACHEDIR="$XDG_CACHE_HOME/zsh-$ZSH_VERSION"
if [[ ! -d "$ZCACHEDIR" ]]; then
    mkdir -p "$ZCACHEDIR"
fi

fpath+=("$ZDOTDIR/comp")

declare -A ZSH_COLORS_RGB=(
    orange "#d08770"
)

setopt combiningchars   # handle combining unicode chars
setopt autocd           # cds on path as command
unsetopt beep           # no annoying beeps
setopt completeinword   # complete inside words, brackets etc 
setopt auto_pushd       # add directories to stack automatically
setopt pushd_ignore_dups

# semi lazily generate and load colors for ls etc
if [[ -z "$LS_COLORS" ]]; then
    color_cache="$ZCACHEDIR/ls_colors"
    if [[ ! -f "$color_cache" ]]; then
        print -n "export LS_COLORS='" > "$color_cache"
        vivid generate "$XDG_CONFIG_HOME/vivid/themes/nord.yaml" >> "$color_cache"
        print -n "'" >> "$color_cache"
    fi
    source "$color_cache"
    unset color_cache
fi

# does pretty much what it says
# does not complete inside quotes (duh)
function __complete_galias {
    if [[ -n "$PREFIX" && -z "$QIPREFIX" ]]; then
        local expl
        _description aliases expl 'alias'
        compadd "${expl[@]}" -- ${(M)${(k)galiases}:#$PREFIX*}
    fi
    return 1
}

#completion opts
zstyle ':completion:*' completer __complete_galias _complete _expand _approximate

# By default, use LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS};ma=100;94"
# For options, 
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt"%F{cyan}%l l%F{8} -m%F{yellow}%m m"
zstyle ':completion:*' list-prompt "%F{cyan}%l l%F{8} - %F{yellow}%m m"
zstyle ':completion:*' verbose false
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}= %d%f'
zstyle ':completion:*:manuals'    separate-sections true
zstyle ':completion:*:manuals:*'  insert-sections   true


autoload -Uz compinit
# only reload comps after reboot effectively
# to reload after e.g. an update, delete the file
if [[ -f "$ZCACHEDIR/compdump" ]]; then
    compinit -C -d "$ZCACHEDIR/compdump"
else
    compinit -d "$ZCACHEDIR/compdump"
    zcompile "$ZCACHEDIR/compdump"
fi
compdef _files '-redirect-' # for some reason wasnt default

# as magick tells me, `convert` is deprecated
compdef magick=convert

#history
HISTFILE="$XDG_DATA_HOME/zsh/histfile"
HISTSIZE=4000
SAVEHIST=8000

# hashed directories (accessible via ~name)
nameddirs=(
    ["cfg"]="$HOME/.config"
    ["dl"]="$HOME/Downloads"
    ["docs"]="$HOME/Documents"
    ["games"]="$HOME/Games"
    ["jrnl"]="$HOME/Documents/journal/journal/"
    ["media"]="/run/media/$USER"
    ["mnt"]="/mnt"
    ["music"]="$HOME/Media/Music"
    ["school"]="$HOME/Documents/school"
    ["tmp"]="$HOME/Tmp"
    ["tmp"]="$HOME/Tmp"
    ["ws"]="$HOME/ws"
)

# my own config
source "$ZDOTDIR/keybinds.zsh"
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/prompt.zsh"
source "$ZDOTDIR/functions.zsh"

# syntax highlighting
source "$ZDOTDIR/highlight.zsh"

# zoxide, cache since that saves a subshell
if [[ ! -f "$ZCACHEDIR/zoxide_init.zsh" ]]; then
    zoxide init zsh > "$ZCACHEDIR/zoxide_init.zsh"
fi
source "$ZCACHEDIR/zoxide_init.zsh"

# like neovim's highlighting
# null: gray; false, true: teal; numbers: magenta; strings: green; array, object separators: gray; keys: blue
export JQ_COLORS="0;90:0;36:0;36:0;35:0;32:0;90:0;97:1;34"

export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
# only set this for interactive sessions
export SSH_ASKPASS_REQUIRE=prefer
