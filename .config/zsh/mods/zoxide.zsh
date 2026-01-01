function _zoxide_directory_name {
    if [[ "$1" == "d" ]]; then
        return 1
    fi

    if [[ "$1" == "n" ]]; then
        local name type resolved
        IFS=":" read -r type name <<< "$2"
        if [[ "$type" != "z" ]]; then
            return 1
        fi

        resolved="$(zoxide query "$name" 2>/dev/null)"
        if [[ -z "$resolved" ]]; then
            return 1
        fi

        typeset -ga reply
        reply=("$(zoxide query "$name")")
        return 0
    fi

    return 1
}

zsh_directory_name_functions+=(_zoxide_directory_name)
