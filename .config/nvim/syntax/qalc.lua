require("config.lib.synkit").syntax("qalc", {
    "set",
    "base",
    "factor",
    "function",
    "variable",
    "quit",
    "exit",
    operator = { "to" },
    ["constant.builtin"] = {
        { "pi", conceal = "π" },
        { "planck2pi", "dirac", conceal = "ħ" },
        { "boltzmann", conceal = "k" },
        "e", "planck", "g_0", "G", "c"
    }
}, {
    comment = { { "#.*$", spell = true } },
    number = { [[
        \<\d\+\.\?\d*
        \<0[xX]\x\+\.\?\x*
        \<0[bB][01]\+\.\?[01]*
        \<0[oO][0-7]\+\.\?[0-7]d*
    ]] },
    operator = { [[
        + - \* /
        \\ \^ +/-
        ! % | &
        < > <= >= =
        ->
    ]] },
    punctuation = { [[
        \[ \] ( ) { }
        ; ,
        \\$
    ]] },
    ["function"] = {
        [[\w\+\((\)\@=]],
        "diff",
        { "sqrt", conceal = "√" },
        { "integral", conceal = "ʃ" },
    },
    ["variable.parameter.builtin"] = {
        [[\\\w]]
    }
})
