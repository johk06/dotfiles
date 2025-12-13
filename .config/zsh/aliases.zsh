alias \
    updategrub="sudo grub-mkconfig -o /boot/grub/grub.cfg" \
    bc="bc -l" \
    svim="sudoedit" \
    sv="sudoedit" \
    nv="nvim" \
    vi="nvim" \
    yay="yay --editmenu --devel" \
    q="exit" \
    rm="rm -i" \
    ll='lsd -l --hyperlink=auto' \
    lls='lsd -l --blocks=size,name --total-size --sort=size' \
    lla='lsd -lA --hyperlink=auto' \
    llv='lsd -l --hyperlink=auto --blocks=group,user,permission,git,date,size,links,name'\
    la='lsd -A --hyperlink=auto' \
    l='lsd --hyperlink=auto' \
    grep='grep --color=auto' \
    g="git" \

alias '#'="noglob qalc" # do math directly on the cmdline

# nice to have redirections
alias \
    -g "@quiet"=">/dev/null 2>&1" \
    -g "@e2o"="2>&1" \
    -g "@o2e"=">&2" \
    -g '@noe'="2>/dev/null" \
    -g "@noo"=">/dev/null" \
    -g "@help"='--help 2>&1 | bat -l help -p' \

TAB=$'\t'
GH="https://github/com"
GHSSH="git@github.com"
