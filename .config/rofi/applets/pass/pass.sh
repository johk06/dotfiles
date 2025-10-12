#!/usr/bin/env bash

list-passwords() {
    local OLDPWD="$PWD"
    cd ~/.password-store || exit 1
    fd --type=file --format '{.}' . .
}

print-menu() {
    local pass="$1"
    printf '\0data\x1f%s\n' "$pass"
    printf '%s\n' "Type" "Type OTP" "Form" "Form with OTP" "Copy" "Copy OTP" "Show"
}

run() {
    ("$@" >/dev/null 2>&1) &
    disown
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

fill-form() {
    account="$1"
    coproc {
        user="$(pass show "$account" | awk -F: 'tolower($1) == "user" { sub(/^[ \t]/, "", $2); print $2}')"
        pass="$(pass show "$account" | head -n 1)"

        if [[ "$2" == "--otp" ]]; then
            token="$(pass otp "$account")"
            printf 'type %s\nkey tab\ntype %s\nkey enter\n' "$user" "$pass" 
            sleep 2
            printf 'type %s\n' "$token"
        else
            printf 'type %s\nkey tab\ntype %s' "$user" "$pass"
        fi | dotool
    }
}

perform-action() {
    local pass="$1"
    local action="$2"
    case "$action" in
    Copy)
        notify-on-copy "Password"
        run pass -c "$pass"
        ;;
    Type)
        coproc {
            dotool <<<"type $(pass show "$pass" | head -n 1)"
        }
        ;;
    "Form")
        fill-form "$pass"
        ;;
    "Form with OTP")
        fill-form "$pass" --otp
        ;;
    "Copy OTP")
        notify-on-copy "OTP Code"
        run pass otp -c "$pass"
        ;;
    "Type OTP")
        coproc {
            dotool <<<"type $(pass otp "$pass")"
        }
        ;;
    Show)
        run pass show "$pass"
        ;;
    *)
        coproc {
            read -r field action <<<"$action"
            match="$(pass show "$pass" | awk -F: -v field="$field" 'tolower($1) == field { sub(/^[ \t]*/, "", $2); print $2; exit }')"
            case "$action" in
            typ*)
                dotool <<<"type $match"
                ;;
            *)
                run wl-copy "$match"
                notify-on-copy "Field: '$field'"
                clear-clipboard 45
                ;;
            esac
        }
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
