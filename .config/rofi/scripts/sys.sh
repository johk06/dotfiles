#!/usr/bin/env bash

print-menu() {
    printf '%s\n%s\0icon\x1f%s\x1finfo\x1f%s\x1fmeta\x1f%s\t' \
        Lock "Lock Session" lock session/lock "" \
        Suspend "Suspend System" sleep session/sleep "sleep" \
        Logout "Exit Session" system-log-out session/logout "" \
        Reboot "Reboot System" system-reboot session/reboot "restart" \
        Shutdown "Shut System down" system-shutdown session/poweroff "off" \
        Wallpaper "Change Wallpaper" wallpaper other/wallpaper "background"
}

power-menu() {
    IFS=/ read -r subitem answer <<<"$1"
    if [[ -z "$answer" ]]; then
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\t' \
            Yes dialog-yes "session/$1/yes" \
            No cancel "session/$1/no"
    else
        if [[ "$answer" != "yes" ]]; then
            exit
        fi

        case "$subitem" in
        lock) gtklock -d ;;
        sleep)
            gtklock -d
            sleep 1
            systemctl suspend
            ;;
        logout)
            if [[ -n "$SWAYSOCK" ]]; then
                swaymsg exit
            fi
            ;;
        reboot) systemctl reboot ;;
        poweroff) systemctl poweroff ;;
        esac
    fi
}

command-menu() {
    case "$1" in
    wallpaper)
        coproc "$XDG_CONFIG_HOME/rofi/applets/wallpapers/run.sh"
        ;;
    esac
}

show-menu() {
    case "$1" in
    session)
        power-menu "$2"
        ;;
    other)
        command-menu "$2"
        ;;
    esac
}

if ((ROFI_RETV == 0)); then
    echo -en "\0delim\x1f\t\n"
    print-menu
else
    IFS=/ read -r menu data <<<"$ROFI_INFO"
    show-menu "$menu" "$data"
fi
