# manually activate shell integration for the parts i care about
if [[ ! -n "$KITTY_SHELL_INTEGRATION_ENABLED" && -n "$KITTY_INSTALLATION_DIR" && "$TERM" == "xterm-kitty" ]] {
    export KITTY_SHELL_INTEGRATION="no-cursor no-title no-prompt-mark"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration"
    kitty-integration
    unfunction kitty-integration

    KITTY_SHELL_INTEGRATION_ENABLED=1
}

if [[ "$KITTY_SHELL_INTEGRATION_ENABLED" != 1 ]] {
    return 1
}
