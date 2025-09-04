#!/usr/bin/env bash

list-passwords() {
    local OLDPWD="$PWD"
    cd ~/.password-store || exit 1
    fd --type=file --format '{.}' . .
}

print-menu() {
    local pass="$1"
    printf '\0data\x1f%s\n' "$pass"
    printf '%s\n' "Copy" "Type" "Copy OTP" "Type OTP" "Show"
}

run() {
    ("$@" >/dev/null 2>&1) &
    disown
}

type-string() {
    coproc {
        dotool <<<"type $1" >/dev/null 2>&1
    }
}

notify-on-copy() {
    local seconds=${2:-45}
    notify-send -i password "$1 copied to clipboard" \
        "Clipboard will be cleared in ${seconds}s"
}

clear-clipboard() {
    coproc {
        local before="$(wl-paste | base64)"
        sleep $1
        local after="$(wl-paste | base64)"
        if [[ "$before" == "$after" ]]; then
            wl-copy -c
        fi
    }
}

perform-action() {
    local pass="$1"
    local action="$2"
    case "$action" in
    Copy)
        run pass -c "$pass"
        notify-on-copy "Password"
        ;;
    Type)
        type-string "$(pass show "$pass" | head -n 1)"
        ;;
    "Copy OTP")
        run pass otp -c "$pass"
        notify-on-copy "OTP Code"
        ;;
    "Type OTP")
        type-string "$(pass otp "$pass" | head -n 1)"
        ;;
    Show)
        pass show "$pass"
        ;;
    *)
        read -r field action <<<"$action"
        match="$(pass show "$pass" | awk -F: -v field="$field" 'tolower($1) == field { sub(/^[ \t]*/, "", $2); print $2; exit }')"
        case "$action" in
        typ*)
            type-string "$match"
            ;;
        *)
            run wl-copy "$match"
            notify-on-copy "Field: '$field'"
            clear-clipboard 45
            ;;
        esac
        ;;
    esac
}

if ((ROFI_RETV != 0)); then
    if [[ -z "$ROFI_DATA" ]]; then
        print-menu "$1"
    else
        perform-action "$ROFI_DATA" "$1"
    fi
else
    list-passwords
fi
