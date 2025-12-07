export VISUAL="nvim"
export EDITOR="nvim"
export npm_config_prefix="$HOME/.local"
export SSH_ASKPASS=/usr/lib/seahorse/ssh-askpass
export SSH_ASKPASS_REQUIRE=prefer
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

path+=("$HOME/.local/bin" "$HOME/.config/bin")

mkdir -p /tmp/workspaces_$USER/{cache,build,download,0,1,2,3,4,5,6,7}
rm -rf $HOME/Tmp $HOME/.cache
ln -s /tmp/workspaces_$USER $HOME/Tmp
ln -s /tmp/workspaces_$USER/cache $HOME/.cache

if [[ $(tty) == /dev/tty* ]]
then
    exec $ZDOTDIR/run_session.sh
fi
