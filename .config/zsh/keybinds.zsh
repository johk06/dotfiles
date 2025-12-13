# vi mode plugin
function zvm_config {
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK  
    ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_BLOCK  
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
    ZVM_VI_SURROUND_BINDKEY=classic
    ZVM_VI_HIGHLIGHT_BACKGROUND=8
    zvm_bindkey vicmd "/" history-incremental-search-backward
}
function zvm_after_init {
    source "$ZDOTDIR/pairs.zsh"
}

source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# fish-like suggestions
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
zvm_bindkey viins '^ ' autosuggest-accept
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,bold"

# history
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search


# general keybinds
bindkey '^Z' push-line

# dont delete as much with C-w
WORDCHARS="*?_-.[]~=!#$%^(){}"
