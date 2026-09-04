if [[ "$HOST" == "hpc" ]]; then
    if [[ ! -f "$ZCACHEDIR/env.zsh" ]]; then
        {
            local cloud_backend="$(pass-get backup/pc backend)"
            local url="$(pass-get "$cloud_backend" backup)"
            printf 'export RESTIC_REPOSITORY=%q\n' "$url"
            printf 'export RESTIC_PASSWORD_COMMAND="pass-get backup/pc ."\n'
        } > "$ZCACHEDIR/env.zsh"
    fi
    source "$ZCACHEDIR/env.zsh"
fi
