if [[ "$HOST" == "hpc" ]]; then
    if [[ ! -f "$ZCACHEDIR/env.zsh" ]]; then
        {
            local cloud_backend="$(pass-get backup/pc backend)"
            local url="$(pass-get "$cloud_backend" backup)"
            printf 'RESTIC_REPOSITORY=%q\n' "$url"
            printf 'RESTIC_PASSWORD_COMMAND="pass-get %s ."\n' "$cloud_backend"
        } > "$ZCACHEDIR/env.zsh"
    fi
    source "$ZCACHEDIR/env.zsh"
fi
