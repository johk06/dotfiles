local title = require("config.langabbrev").title

---@type config.AbbrevSpec[]
local M = {
    { "zw",  "zwischen",        case_variants = true },
    { "zb",  "zum Beispiel",    case_variants = true },
    { "bzw", "beziehungsweise", case_variants = true }
}

local verb_suffixes = {
    r = "en",
    t = "t",
    e = "e",
    d = "end",
    de = "ende",
    ds = "endes",
    dr = "ender",
    b = "bar",
    be = "bare",
    bs = "bares",
    br = "barer"
}

local noun_suffixes = {
    [""] = "",
    n = "en",
}

local latinate_verb = function(abbrev, stem)
    table.insert(M, {
        abbrev,
        stem,
        suffixes = verb_suffixes,
        case_variants = true,
    })
end

local weak_noun = function(abbrev, stem)
    table.insert(M, {
        abbrev,
        title(stem),
        suffixes = noun_suffixes
    })
end

local latinate_root_basic = function(abbrev, stem)
    latinate_verb(abbrev, stem .. "ier")
    weak_noun(abbrev, stem)
end

-- Common Math Words {{{
latinate_verb("dfn", "defin")
weak_noun("dfn", "definition")
latinate_root_basic("fnk", "funktion")
latinate_root_basic("dfz", "differenz")

latinate_verb("itg", "integr")
table.insert(M, {
    "itg",
    "Integral",
    suffixes = { [""] = "", n = "en", e = "e" }
})
-- }}}

-- Ordinals {{{
local ordinal_suffixes = {
    e = "",
    r = false,
    s = false,
    n = false,
    ns = false,
}

for n, ordinal in ipairs {
    "letz", "ers", "zwei", "drit", "vier",
    "fünf", "sechs", "sieb", "ach", "neun",
    "zehn", "elf", "zwölf"
} do
    table.insert(M, {
        n - 1,
        ordinal .. "te",
        suffixes = ordinal_suffixes,
        case_variants = true,
    })
end
-- }}}

return M
