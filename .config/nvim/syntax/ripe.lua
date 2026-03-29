---@type synkit.Keywords
local keywords = {
    boolean = {
        "true", "false", "nil"
    },
    -- NOTE: there is of course no such thing as an operator in ripe, but this
    -- is close enough
    operator = {
        "+", "-", "*", "/", "^", "%",
        "c+", "c-", "c*", "c/", "c^",
        "<-",
        "=", "~", "<", "<=", ">", ">="
    },
    ["keyword.conditional"] = {
        "if", "when", "unless"
    },
    ["keyword.repeat"] = {
        "loop", "repeat", "for+", "for-", "for", "fori",
        "foreach+", "foreach-", "foreach#"
    },
    ["keyword.operator"] = {
        "quote", "unquote", "apply", "type", "height"
    },
}

---@type synkit.Matches
local matches = {
    ["punctuation.bracket"] = {
        "\\[", "\\]", "{",
        [[}\<\ze\k\+\>]]
    },
    ["string.escape"] = {
        {
            [=[\\["ntre\\]]=],
            contained = true,
            containedin = {
                "string"
            }
        }
    },
    ["punctuation.special"] = {
        [['\ze\<\k\+\>]]
    },
    ["number"] = {
        [=[-\?\d\+\%(\.\d\+\)\?\%(e[+-]\?\d\+\)\?]=],
        [[-\?0x\x\+]],
        [[-\?0o[0-7]\+]],
        [[-\?0b[01]\+]],
    }
}

---@type synkit.Regions
local regions = {
    string = {
        start = [["]],
        stop = [["]],
        skip = [[\\"]],
        contains = {
            "string.escape"
        }
    },
    ["string.raw"] = {
        start = "`",
        stop = "`",
        skip = [[\\`]]
    },
    comment = {
        start = "(",
        stop = ")",
        extra = "extend",
        contains = {
            "comment"
        }
    }
}

require("config.lib.synkit").syntax {
    name = "ripe",
    regions = regions,
    iskeyword = "@,!-&,*-/,:-64,\\,_,`,~,^",
    keywords = keywords,
    match = matches,
}
