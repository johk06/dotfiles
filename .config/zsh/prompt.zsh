psvar=(
    0             # 1 time of previous command
    ""            # 2 git branch
    ""            # 3 git modified
    ""            # 4 git deleted
    ""            # 5 git added
    ""            # 6 git renamed
    ""            # 7 git ahead
    ""            # 8 git behind
    ""            # 9 current dir readable
    "12"          # 10 color based on return status
    ""            # 11 symbol/text to be used for return status
)


function _update_git_status {
    # only update if inside a git dir that isnt ignored
    git check-ignore -q . 2>/dev/null
    # returns 0 if dir ignored and 1 if not but still git
    if (($? == 1)); then
        local type gstatus submod file
        local modified="" deleted="" added="" renamed="" smodified="" sdeleted="" sadded="" _branch branch="" remote="" ahead="" behind=""
        git status --porcelain=v2 --untracked-files=no --ignored=no --branch . 2>/dev/null \
            | while read -r type gstatus submod _ _ _ file; do
            case "$type" in
                (\#)
                    case "$gstatus" in
                        (branch.oid);;
                        (branch.head) branch="$submod";;
                        (branch.upstream) upstream="$submod";;
                        (branch.ab)
                            ahead="$submod"
                            behind="$hname"
                            ahead="${ahead#+}"
                            behind="${behind#-}"
                            [[ "$ahead" == -* ]] && behind="${ahead#-}"

                            [[ "$ahead" == 0 ]] && ahead=""
                            [[ "$behind" == 0 ]] && behind=""
                            ;;
                    esac
                    ;;
                (1)
                    case "$gstatus" in
                        (.A) ((added++));;
                        (.D) ((deleted++));;
                        (.M) ((modified++));;
                        (AA|A.) ((added++)); sadded=.;;
                        (DD|D.) ((deleted++)); sdeleted=.;;
                        (MM|M.) ((modified++)); smodified=.;;
                    esac
                    ;;
                (2)
                    case "$gstatus" in
                        R.|RM) ((renamed++));;
                    esac
                    ;;
            esac
        done

        printf "%s;%s;%s;%s;%s;%s;%s\n" \
            "$branch" "$modified$smodified" "$deleted$sdeleted" "$added$sadded" "$renamed" "$ahead" "$behind"
    else
        echo
    fi
}


PROMPT=$'%{\e]133;A\a%}' # OSC133 start
# current working directory [ro]
PROMPT+="%F{cyan}%(6~|%-1~/…/%24<..<%3~%<<|%6~)%u%(9V. %F{11}[ro].)"
# git status: [+ahead] [-behind] HEAD [+added] [~changed] [-removed] [->moved]
PROMPT+="%(2V.%F{8} /%(7V.%F{green}+%7v .)%(8V.%F{red}-%8v .)%F{white}%2v%(5V. %F{green}+%5v.)%(3V. %F{yellow}~%3v.)%(4V. %F{red}-%4v.)%(6V. %F{magenta}->%6v.).)"
# processes, time taken, date
PROMPT+="%F{8} |%(1j. %F{12}&%j.) %f%1v%F{8}, %F{%10v}%11v"
# prompt symbol
PROMPT+="
%F{cyan}ρ%f "
PROMPT+=$'%{\e]133;B\a%}' # OSC133 end

# #history-number Jan 1 00:00
RPROMPT="%{$(echotc UP 1)%}%F{magenta}#%h %F{13}%D{%b %d} %F{12}%D{%H:%M}%{$(echotc DO 1)%}"

declare -A _exitcolors=(
    [0]=green
    [130]=yellow
    [147]=blue
    [148]=blue
)

# run process for git status asynchronously
_PROMPTPROC=0

# use a pseudo anonymous pipe
# TODO: find a way to avoid non shell built ins
mkfifo "$ZCACHEDIR/prompt_$$"
exec {_PROMPTFD}<> "$ZCACHEDIR/prompt_$$"
unlink "$ZCACHEDIR/prompt_$$" &!

function preexec {
    _PROMPTTIMER=$EPOCHREALTIME
    print -n "\e]133;C\a"

    # show current cmd in title
    local cmd=(${(z)1})
    print -Pn "\e]0;${1}\a"
}

function precmd {
    local exitc=$?
    print -n "\e]133;D;$exitc\a"

    if ((_PROMPTPROC != 0)); then
        kill -s HUP $_PROMPTPROC >/dev/null 2>&1 || :
    fi

    ( _update_git_status >&$_PROMPTFD
        kill -s USR1 $$ >/dev/null 2>&1
    ) &!
    _PROMPTPROC=$!

    if ((exitc > 128 && exitc < 256)); then
        local signame="${signals[exitc-127]:l}"
        if [[ -n "$signame" ]]; then
            psvar[11]="!${signame}: $exitc"
        else
            psvar[11]="!$exitc"
        fi
    else
        if ((! exitc)); then
            psvar[11]="ok"
        else
            psvar[11]="err: $exitc"
        fi
    fi
    psvar[10]="${_exitcolors[$exitc]}"
    if [[ -z "${psvar[10]}" ]]; then
        psvar[10]=red
    fi

    # dont print a new time on every single <cr>, just if a command ran
    if (( _PROMPTTIMER)); then
        local elapsed_ms=$[ ( $EPOCHREALTIME-$_PROMPTTIMER )* 1000 ] elapsed
        if (( elapsed_ms > 60000 )) {
            # print everything over a minute as MM:SS
            printf -v elapsed "%02.0f:%02.0f" $[ ($elapsed_ms/1000.0) / 60 ] $[ ($elapsed_ms/1000.0) % 60 ]
        } elif (( elapsed_ms >= 100 )) {
            printf -v elapsed "%.2fs" $[ $elapsed_ms/1000.0 ]
        } else  {
            printf -v elapsed "%.2fms" $elapsed_ms
        }
        psvar[1]=$elapsed
    fi
    # set the title
    print -Pn "\e]0;zsh%(1j. %j&.): %~\a"
    if [[ ! -w "$PWD" ]]; then
        psvar[9]=1
    else
        psvar[9]=""
    fi
    _PROMPTTIMER=0
}

function TRAPUSR1 {
    local -a tmp
    IFS=";" read -u $_PROMPTFD -rA tmp
    psvar[2]=${tmp[1]}
    psvar[3]=${tmp[2]}
    psvar[4]=${tmp[3]}
    psvar[5]=${tmp[4]}
    psvar[6]=${tmp[5]}
    psvar[7]=${tmp[6]}
    psvar[8]=${tmp[7]}

    _PROMPTPROC=0

    zle -I && zle reset-prompt
}

# Prompt for nested things:
PS2="%F{8}%_ │%f "

# sudo prompt
print -P -v SUDO_PROMPT "%F{8}[%f%B%F{red}sudo%f%b as %B%%U%b%F{8}]#%f "
export SUDO_PROMPT

# only the default, i have a couple more functions planed for this
TIMEFMT="User   %U
Kernel %S
Time   %E"

# disable python venv automatic prompt changing
export VIRTUAL_ENV_DISABLE_PROMPT=1
