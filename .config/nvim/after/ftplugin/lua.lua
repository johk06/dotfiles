vim.b.snippets = {
    f = {
        "function($1)",
        "    $0",
        "end"
    },
    d = {
        "local ${1:name} = function($2)",
        "    $0",
        "end",
    },
    l = "local ${1:var} = ${2:val}",
    r = "require(\"${1}\")",
    i = {
        "for ${1:i}, ${2:v} in ipairs(${3:tbl}) do",
        "    $0",
        "end"
    },
    p = {
        "for ${1:k}, ${2:v} in pairs(${3:tbl}) do",
        "    $0",
        "end"
    }
}
