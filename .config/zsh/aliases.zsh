alias \
    updategrub="sudo grub-mkconfig -o /boot/grub/grub.cfg" \
    bc="bc -l" \
    svim="sudoedit" \
    sv="sudoedit" \
    nv="nvim" \
    yay="yay --editmenu --devel" \
    mpv="mpv --hwdec=auto" \
    q="exit" \
    x="exit" \
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
    -g "@err2out"="2>&1" \
    -g "@out2err"=">&2" \
    -g '@noerr'="2>/dev/null" \
    -g "@noout"=">/dev/null" \
    -g "@help"='--help 2>&1 | bat -l help -p' \


alias \
    '@raw'="noglob" \
    ':tab'="IFS=$'\t'" \
    ':colon'="IFS=':'" \
    ':semic'="IFS=';'" \
    ':lf'="IFS=$'\n'" \
    ':eq'="IFS='='"

TAB=$'\t'
