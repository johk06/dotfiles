local verb_suffixes = {
    r = "en",
    rt = "t",
    re = "e",
    rd = "end",
    de = "ende",
    ds = "endes",
    dr = "ender",
    b = "bar",
    be = "bare",
    bn = "baren",
    bs = "bares",
    br = "barer"
}

local noun_suffixes = {
    _ = "",
    e = "e",
    n = "en",
    s = "s",
}

---@type config.AbbrevSpec[]
local M = {
    { "zw",   "zwischen" },
    { "zb",   "zum Beispiel" },
    { "bsp",  "Beispiel",       noun_suffixes },
    { "bspw", "beispielsweise" },
    { "bzw",  "beziehungsweise" },
    { "fA",   "für alle" },
    { "vA",   "vor allem" },
    {"unsh", "Unsicherheit", noun_suffixes},
    { "fnk",  "funktionier",    verb_suffixes },
    { "fnk",  "Funktion",       noun_suffixes },
    { "dfz",  "differenz",      verb_suffixes },
    { "dfz",  "differenzier",   verb_suffixes },
    { "dfn",  "definier",       verb_suffixes },
    { "dfn",  "Definition",     noun_suffixes },
    { "itg",  "integrier",      verb_suffixes },
    { "itg",  "Integral",       { _ = "", e = "e", n = "en" },                                 nocase = true },
}

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
        n - 1 .. "t",
        ordinal .. "te",
        ordinal_suffixes,
    })
end
-- }}}

return M
