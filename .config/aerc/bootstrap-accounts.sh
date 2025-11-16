#!/usr/bin/bash

ACCOUNT_CONF="$XDG_CONFIG_HOME/aerc/accounts.conf"
if [ -f "$ACCOUNT_CONF" ] && [ "$1" != "reload" ]; then
    exit
fi

pass mail/accounts | while IFS="|" read -r name realname address imapserver smtpserver pass default_folder; do
    {
        read -r user
        read -r password
    } < <(pass-get "$pass" user . | jq -Rr @uri)
    echo "[$name]"
    echo "from = $realname <$address>"
    printf "source = $imapserver\n" "$user" "$password"
    printf "outgoing = $smtpserver\n" "$user" "$password"
    echo "default = $default_folder"
    echo
done >"$ACCOUNT_CONF"
chmod 600 "$ACCOUNT_CONF"
if [ "$1" != "reload" ]; then
    notify-send "Configured Accounts" "Please start aerc again"
    (
        sleep 1
        kill -HUP $PPID
    ) &
    disown
fi
