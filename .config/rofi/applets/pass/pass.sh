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

error() {
    notify-send "$1" -i password "$2"
}

error-otp() {
    error "No OTP Code" "No OTP Code for $1"
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
        {
            read -r user
            read -r pass
        } < <(pass-get "$account" user .)

        if [[ "$2" == "--otp" ]]; then
            printf 'type %s\nkey tab\ntype %s\nkey enter\n' "$user" "$pass"
            sleep 2
            if ! token="$(pass otp "$account")"; then
                error-otp "$account"
                exit
            fi
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
        coproc {
            pass -c "$pass"
        }
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
        coproc {
            pass otp -c "$pass" || {
                error-otp "$pass"
                exit
            }
            notify-on-copy "OTP Code"
        }
        ;;
    "Type OTP")
        coproc {
            if ! token="$(pass otp "$pass")"; then
                error-otp "$pass"
            fi
            dotool <<<"type $token"
        }
        ;;
    Show)
        pass show "$pass" | while read -r line; do
            true
        done
        ;;
    *)
        coproc {
            read -r field action <<<"$action"
            match="$(pass-get "$pass" "$field")"
            if [[ -z "$match" ]]; then
                error "Missing Field" "No field '$field' in entry '$pass'"
            fi
            case "$action" in
            typ*)
                dotool <<<"type $match"
                ;;
            *)
                wl-copy "$match"
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
