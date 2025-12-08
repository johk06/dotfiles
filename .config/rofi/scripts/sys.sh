#!/usr/bin/env bash

MENUFMT="%s\n%s\0icon\x1f%s\x1finfo\x1f%s\x1fmeta\x1f%s\t"

print-menu() {
    printf "$MENUFMT" \
        Lock "Lock Session" lock session/lock "" \
        Suspend "Suspend System" sleep session/suspend "sleep" \
        Logout "Exit Session" system-log-out session/logout "" \
        Reboot "Reboot System" system-reboot session/reboot "restart" \
        Shutdown "Shut System down" system-shutdown session/halt "off power" \
        Wallpaper "Change Wallpaper" wallpaper other/wallpaper "background" \
        Schedule "Manage AT Jobs" clock sched/manage ""
}

power-menu() {
    IFS=/ read -r subitem answer <<<"$1"
    if [[ -z "$answer" ]]; then
        printf '\0prompt\x1fDo you want to %s?\t' "$subitem"
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\t' \
            Yes dialog-yes "session/$1/yes" \
            No cancel "session/$1/no"
    else
        if [[ "$answer" != "yes" ]]; then
            exit
        fi

        case "$subitem" in
        lock) gtklock -d ;;
        suspend)
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
        halt) systemctl poweroff ;;
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
    session) power-menu "$2" ;;
    other) command-menu "$2" ;;
    sched) sched-menu "$2" ;;
    esac
}

sched-menu() {
    IFS=/ read -r sub task <<<"$1"
    case "$sub" in
    manage)
        printf "$MENUFMT" \
            Notify "Schedule notification for some time" preferences-desktop-notification sched/notify "msg" \
            List "Show currently schedule Jobs" application-text sched/list "ls"
        ;;
    list)
        atq | while read -r id wday month day time year queue user; do
            printf "$MENUFMT" \
                "$time on $wday $month $day" "by $user in queue $queue" suspend sched/task/"$id" ""
        done
        ;;
    notify)
        coproc {
            out="$(yad --form --field=Time --field=Title --field=Message --field=Level:CB \
                '' '' '' 'low!^normal!critical' --buttons-layout=edge --button=Schedule:0 --button=Abort:1)"
            if $?; then
                exit
            fi
            IFS="|" read -r time title msg level <<<"$out"
            printf 'notify-send %q %q -u %q' "$title" "$msg" "$level" | at "$time"
        }
        ;;
    task)
        IFS=/ read -r id action <<<"$task"
        case "$action" in
        "")
            printf "$MENUFMT" \
                View "Show Commands to run" shellscript sched/task/"$id"/view "edit" \
                Delete "Unschedule Job" emblem-remove sched/task/"$id"/rm ""
            ;;
        view)
            coproc {
                local file="$(mktemp --suffix=.sh)"
                at -c "$id" >"$file"
                xdg-open "$file"
            }
            ;;
        rm)
            atrm "$id"
            sched-menu list
            ;;
        esac
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
