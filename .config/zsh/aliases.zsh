alias \
    g="git" \
    sv="sudoedit" \
    nv="nvim" \
    vi="nvim" \
    svim="sudoedit" \
    yay="yay --editmenu --devel" \
    q="exit" \
    rm="rm -i" \
    l='lsd --hyperlink=auto' \
    ll='lsd -l --hyperlink=auto' \
    la='lsd -A --hyperlink=auto' \
    lla='lsd -lA --hyperlink=auto' \
    lls='lsd -l --blocks=size,name --total-size --sort=size' \
    llv='lsd -l --hyperlink=auto --blocks=group,user,permission,git,date,size,links,name' \
    grep='grep --color=auto'

# Intelligently request stuff from the internet
# Mainly to build up a more complex pipeline
alias req='noglob cache - curl -s'

alias '#'="noglob qalc" # do math directly on the cmdline

# nice to have redirections
alias \
    -g "@quiet"=">/dev/null 2>&1" \
    -g "@help"='--help 2>&1 | bat -l help -p'

TAB=$'\t'
GH="https://github.com"
GHSSH="git@github.com"
