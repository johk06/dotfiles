---@type config.snippet_map
return {
    func = {
        "function($1)",
        "\t$0",
        "end"
    },
    pairs = {
        "for k, ${1:v} in pairs(${2:tbl}) do",
        "\t$0",
        "end"
    },
    ipairs = {
        "for i, ${1:v} in ipairs(${2:tbl}) do",
        "\t$0",
        "end"
    },
    ["local"] = {
        "local $1 = $0"
    },
    ["true"] = "true",
    ["false"] = "false",
    ["return"] = "return",
}
