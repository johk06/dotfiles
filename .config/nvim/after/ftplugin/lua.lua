vim.b.snippets = {
    f = "function($1) $0 end",
    l = "local ${var} = ${val}",
    r = "require(\"${1}\")",
    p = {
        "for ${1:i}, ${2:v} in ipairs(${3:tbl}) do",
        "    $0",
        "end"
    },
    P = {
        "for ${1:k}, ${2:v} in pairs(${3:tbl}) do",
        "    $0",
        "end"
    }
}
