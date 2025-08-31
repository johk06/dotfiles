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

perform-action() {
    local pass="$1"
    local action="$2"
    case "$action" in
    Copy)
        run pass -c "$pass"
        ;;
    Type)
        type-string "$(pass show "$pass" | head -n 1)"
        ;;
    "Copy OTP")
        run pass otp -c "$pass"
        ;;
    "Type OTP")
        type-string "$(pass otp "$pass" | head -n 1)"
        ;;
    Show)
        pass show "$pass"
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
