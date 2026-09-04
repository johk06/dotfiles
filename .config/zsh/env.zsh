if [[ ! -f "$ZCACHEDIR/env.zsh" ]]; then
    {
        local cloud_backend="$(pass-get backup/main backend)"
        local url="$(pass-get "$cloud_backend" backup)"
        printf 'export RESTIC_REPOSITORY=%q:%q\n' "$url" "$HOST"
        printf 'export RESTIC_PASSWORD_COMMAND="pass-get backup/main ."\n'
    } > "$ZCACHEDIR/env.zsh"
fi
source "$ZCACHEDIR/env.zsh"
