# manually activate shell integration for the parts i care about

export KITTY_SHELL_INTEGRATION="no-cursor no-title no-prompt-mark"
autoload -Uz -- "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
kitty-integration
unfunction kitty-integration

kitty @ env LS_COLORS="$LS_COLORS"

KITTY_SHELL_INTEGRATION_ENABLED=1
