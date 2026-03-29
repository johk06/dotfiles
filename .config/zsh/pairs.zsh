# my own autopair system

declare -gA AUTOPAIR_PAIRS=(
    \`  \`
    \"  \"
    \'  \'
    \(  \)
    \{  \}
    "["  "]"
)
declare -gA AUTOPAIR_PAIRS_INV=(
    \` \`
    \" \"
    \' \'
    \) \(
    \} \{
    "]" "["
)

function _autopair_line_is_balanced {
    local lbuf="${LBUFFER//\\$1}"
    local rbuf="${RBUFFER//\\$2}"
    local llen="${#lbuf//[^$1]}"
    local rlen="${#rbuf//[^$2]}"

    if (( rlen == 0 && llen == 0 )); then
        return 0
    elif [[ "$1" == "$2" ]]; then 
        if ((llen == rlen || (llen + rlen) % 2 == 0 )); then
            return 0
        fi
    else
        local l2len="${#lbuf//[^$2]}"
        local r2len="${#rbuf//[^$1]}"
        local ltotal=$(( llen - l2len ))
        local rtotal=$(( rlen - r2len ))

        (( ltotal < 0 )) && ltotal=0
        (( ltotal < rtotal )) && return 1

        return 0
    fi

    return 1
}

function _autopair_can_skip {
    if [[ -z "$LBUFFER" ]]; then
        return 1
    elif [[ "$1" == "$2" ]] && ! _autopair_line_is_balanced "$1" "$2"; then
        return 1
    fi
    if ! [[ -n "$2" && $RBUFFER[1] == "$2" && $LBUFFER[-1] != '\' ]]; then
        return 1
    fi

    return 0
}
    
function _autopair_can_delete {
    local lchar="${LBUFFER[-1]}"
    local rchar="${AUTOPAIR_PAIRS[$lchar]}"
    if [[ "${RBUFFER[1]}" != "$rchar" ]]; then
        return 1
    fi

    if [[ "$lchar" == "$rchar" ]] && ! _autopair_line_is_balanced "$lchar" "$rchar"; then
        return 1
    fi

    return 0
}

function _autopair_can_delete_left {
    local rchar="${RBUFFER[1]}"
    local lchar="${AUTOPAIR_PAIRS_INV[$rchar]}"
    if [[ "${LBUFFER[-1]}" != "$lchar" ]]; then
        return 1
    fi

    if [[ "$lchar" == "$rchar" ]] && ! _autopair_line_is_balanced "$lchar" "$rchar"; then
        return 1
    fi

    return 0
}

function _autopair_can_pair {
    if ! _autopair_line_is_balanced "$1" "$2"; then
        return 1
    elif [[ "$1" == (\'|\"\`) ]] && [[ "$LBUFFER" =~ '[]})a-zA-Z0-9]$' || "$RBUFFER" =~ '^[a-zA-Z0-9]' ]]; then
        return 1
    elif [[ "$LBUFFER" =~ '[.:/\!]$' ]] || [[ "$RBUFFER" =~ '^[[{(<,.:?/%$!a-zA-Z0-9]' ]]; then
        return 1
    fi

    return 0
}

function autopair-insert-char {
    local right="${AUTOPAIR_PAIRS[$KEYS]}"
    if [[ "$KEYS" == "$right" ]] && _autopair_can_skip "$KEYS" "$right"; then
        zle forward-char
    elif _autopair_can_pair "$KEYS" "$right"; then
        LBUFFER+="$KEYS"
        RBUFFER="$right$RBUFFER"
    else
        zle self-insert
    fi
}

function autopair-del-char {
    if _autopair_can_delete; then
        RBUFFER=${RBUFFER:1}
    fi
    zle backward-delete-char
}

function autopair-del-char-right {
    if _autopair_can_delete_left; then
        zle backward-delete-char
    fi
    zle delete-char

}

function autopair-close-pair {
    if _autopair_can_skip "${AUTOPAIR_PAIRS_INV[$KEYS]}" "$KEYS"; then
        zle forward-char
    else
        zle self-insert
    fi
}

zle -N autopair-insert-char
zle -N autopair-del-char
zle -N autopair-del-char-right
zle -N autopair-close-pair

for pair match in "${(kv)AUTOPAIR_PAIRS[@]}"; do
    bindkey "$pair" autopair-insert-char
    if [[ "$match" != "$pair" ]]; then
        bindkey "$match" autopair-close-pair
    fi
done
bindkey -M viins "^H" autopair-del-char
bindkey -M viins "^?" autopair-del-char
bindkey -M command "^H" backward-delete-char
bindkey -M command "^?" backward-delete-char

bindkey -M viins "\e[3~" autopair-del-char-right
bindkey -M command "\e[3~" backward-delete-char

unset pair match
