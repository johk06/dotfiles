#!/usr/bin/env bash

function get_active {
    nmcli -g TYPE,ACTIVE,UUID,NAME connection show \
        |awk -F":" '
            $1 == "wireguard" && $2 == "yes" {
                printf "{\"active\": true, \"name\":\"%s\", \"uuid\":\"%s\"}\n",$4,$3;
                fflush();
                exit 1;
            }' && echo '{"active": false, "name": "", "uuid": ""}'
}

function list_vpns {
    nmcli -g TYPE,ACTIVE,UUID,AUTOCONNECT,NAME connection show \
        |while IFS=":" read -r type active uuid autoconnect name; do
            if [[ "$type" != "wireguard" ]]; then
                continue
            fi

            [[ "$active" == "yes" ]] && bactive=true || bactive=false
            [[ "$autoconnect" == "yes" ]] && bauto=true || bauto=false

            printf '{"active":%s,"autoconnect":%s,"name":"%s","uuid":"%s"}\n' \
                "$bactive" "$bauto" "$name" "$uuid"
            done|jq -s 'sort_by(.name)'
}

case "$1" in
    listen)
        get_active
        nmcli monitor | while read -r _; do get_active; done 
        ;;
    list)
        list_vpns
        ;;
esac
