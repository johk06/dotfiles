if exists('b:current_syntax')
    finish
endif
let b:current_syntax = "qalculate"

syn match qalcComment '#.*$' contains=@Spell

syn match qalcNumber '\<\d\+\.\?\d*'
syn match qalcNumber '\<0[xX]\x\+\.\?\x*'
syn match qalcNumber '\<0[bB][01]\+\.\?[01]*'
syn match qalcNumber '\<0[oO][0-7]\+\.\?[0-7]d*'

syn match qalcOperator '\*' conceal cchar=·
syn match qalcOperator '+'
syn match qalcOperator '/'
syn match qalcOperator '\\'
syn match qalcOperator '+'
syn match qalcOperator '-'
syn match qalcOperator '\^'
syn match qalcOperator '+/-' conceal cchar=±
syn match qalcOperator '±'
syn match qalcOperator '!'
syn match qalcOperator '%'
syn match qalcOperator '|'
syn match qalcOperator '&'
syn match qalcOperator '<'
syn match qalcOperator '>'
syn match qalcOperator '>=' conceal cchar=≥
syn match qalcOperator '<=' conceal cchar=≤
syn match qalcOperator '='

syn match qalcBracket '\['
syn match qalcBracket '\]'
syn match qalcBracket '('
syn match qalcBracket ')'
syn match qalcBracket '{'
syn match qalcBracket '}'
syn match qalcComma ';'
syn match qalcComma ','
" NOTE: this is only part of my qalc-script wrapper
syn match qalcLineContinuation '\\$'

syn match qalcFunction '\w\+\((\)\@='

syn match qalcFunction 'diff'
syn match qalcFunction 'sqrt' conceal cchar=√
syn match qalcFunction 'integral' conceal cchar=ʃ


syn match qalcUnit '\<partial fraction\>'

syn keyword qalcKeyword to
syn match qalcKeyword '->'
syn keyword qalcKeyword set
syn keyword qalcKeyword base
syn keyword qalcKeyword factor
syn keyword qalcKeyword function variable
syn keyword qalcKeyword quit exit

syn match qalcParam '\\\w'

syn keyword qalcConstant pi conceal cchar=π
syn keyword qalcConstant planck2pi dirac conceal cchar=ħ
syn keyword qalcConstant e planck g_0 G c
syn keyword qalcConstant boltzmann conceal cchar=k

hi link qalcComment Comment
hi link qalcBracket Delimiter
hi link qalcComma Delimiter
hi link qalcLineContinuation Delimiter
hi link qalcNumber Number
hi link qalcKeyword Keyword
hi link qalcOperator Operator
hi link qalcUnit String
hi link qalcFunction PreProc
hi link qalcConstant @constant.builtin
hi link qalcParam SpecialChar
