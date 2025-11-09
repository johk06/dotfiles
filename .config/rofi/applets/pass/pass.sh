#!/usr/bin/env bash

list-passwords() {
    local OLDPWD="$PWD"
    cd ~/.password-store || exit 1
    fd --type=file --format '{.}' . . | tr '\n' '\t'
}

print-menu() {
    local pass="$1"
    printf '\0data\x1f%s\t' "$pass"
    printf '%s\t' "Pass" "OTP" "Form" "Form, no OTP" "Copy" "Copy OTP" "Show"
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

show-entry() {
    IFS=":" read _ value <<<"$ROFI_DATA"
    if [[ -z "$value" ]]; then
        printf '\0data\x1f%s\t' "*entry*:$ROFI_INFO"
        printf '%s\t' "Type" "Copy"
    else
        case "$1" in
        Type)
            coproc {
                dotool <<<"type $value"
            }
            ;;
        Copy)
            notify-on-copy "Field"
            coproc {
                pass -c "$value"
            }
            ;;
        esac
    fi
}

perform-action() {
    local pass="$1"
    local action="$2"
    if [[ "$pass" == "*entry*"* ]]; then
        show-entry "$action"
        exit
    fi

    case "$action" in
    Copy)
        notify-on-copy "Password"
        coproc {
            pass -c "$pass"
        }
        ;;
    Pass)
        coproc {
            dotool <<<"type $(pass show "$pass" | head -n 1)"
        }
        ;;
    Form)
        fill-form "$pass" --otp
        ;;
    "Form, no OTP")
        fill-form "$pass"
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
    "OTP")
        coproc {
            if ! token="$(pass otp "$pass")"; then
                error-otp "$pass"
            fi
            dotool <<<"type $token"
        }
        ;;
    Show)
        printf '\0data\x1f*entry*\t'
        pass show "$pass" | while IFS=": " read -r field value; do
            if [[ "$field" == "otpauth" ]]; then
                printf 'OTP-Code\n%s\0info\x1f%s\t' "$field:$value" "$field:$value"
            elif [[ -z "$value" ]]; then
                printf 'Password\n%s\0info\x1f%s\t' "$field" "$field"
            else
                printf '%s\n%s\0info\x1f%s\t' "$field" "$value" "$value"
            fi
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
    echo -en "\0delim\x1f\t\n"
    list-passwords
fi
