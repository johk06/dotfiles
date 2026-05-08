---@type synkit.Keywords
local keywords = {}

---@type synkit.Matches
local patterns = {
    ["markup.link.url"] = {
        "^otpauth://.*",
        priority = 100,
    },
    property = {
        "^[^:]\\+: "
    },
    constant = {
        "\\%1l.*"
    }
}

require("config.lib.synkit").syntax {
    name = "pass",
    regions = {},
    keywords = keywords,
    match = patterns
}
