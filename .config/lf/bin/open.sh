#!/bin/bash -e
IFS=$'\n'

function escape {
    sed -z 's/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g;s/^/"/;s/$/"/'
}

function aescape {
    printf '%s\n' "$@" | jq --raw-input -rj '@sh, " "'
}

function run_in_tty {
    lf -remote "send $id \${{ $(aescape "$@") }}"
}

ARCHIVEDIR="$HOME/Tmp/arc"
ARCLIST="$ARCHIVEDIR/.open.list"
[[ ! -d "$ARCHIVEDIR" ]] && mkdir -p "$ARCHIVEDIR"

function create_arccache {
    local id="$(stat -c "%m.%i.%Y" -- "$1")"
    id="${1##*/}${id//\//@}"
    REPLY="$ARCHIVEDIR/$id$2"
    [[ ! -e "$REPLY" ]]
}

MIMETYPE="$(file --mime-type --brief --dereference -- "$f")"
case "$MIMETYPE" in
audio/*)
    clear
    run_in_tty mpv --no-audio-display -- $fx
    ;;
application/pdf)
    zathura -- $fx &
    disown
    ;;
image/*)
    imv_pid="$(pidof imv-"${XDG_SESSION_TYPE,,}" || echo)"
    if [[ -z "$imv_pid" ]]; then
        echo "$fx" | imv &
        disown
    else
        # FIXME: imv performs shell expansions
        imv-msg "$imv_pid" open "$(aescape "$fx")" next
        imv-msg "$imv_pid" next
    fi
    ;;
text/* | application/json | inode/x-empty | application/javascript | application/x-wine-extension-ini)
    # just let neovim deal with everything
    if [[ -n "$NVIM" ]]; then
        run_in_tty nvr "$fx"
    else
        run_in_tty nvim -b -- $fx
    fi

    ;;
application/x-archive | application/x-cpio | application/x-tar | application/x-bzip2 | application/gzip | application/x-lzip | application/x-lzma | application/x-xz | application/x-7z-compressed | application/vnd.android.package-archive | application/vnd.debian.binary-package | application/java-archive | application/x-gtar | application/zip | application/vnd.rar | application/x-iso9660-image)

    if [[ "$f" == *.xopp ]]; then
        xournalpp "$f"
    else
        if create_arccache "$f" "#x"; then
            # create
            mkdir "$REPLY"
            case "$MIMETYPE" in
            *)
                bsdtar -C "$REPLY" -x -f "$f"
                ;;
            esac

            printf "%s\0%s\n" "$f" "$REPLY" >>"$ARCLIST"
        fi
        lf -remote "send $id cd $(printf '%s' "$REPLY" | escape)"
    fi

    ;;
video/*)
    mpv $fx & disown
    ;;
*)
    for file in $fx; do
        xdg-open "$file" &
        disown
    done
    ;;
esac
