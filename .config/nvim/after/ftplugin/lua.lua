local utils = require("config.utils")
local map = utils.ft_mapper()
local A = utils.A

map("n", "<localleader>f", [[ysa")%a:format()<Left>]], {
    remap = true,
    desc = "Lua: Format string"
})

map("n", "<localleader>p", function()
    vim.cmd([[keeppatterns s/(\s*/, /]])
    vim.cmd.normal { "ipcall(", bang = true }
end, { desc = "Lua: Protect Call" })

local loop_snippet = function(vars, iterator)
    return {
        ("for %s in %s do"):format(vars, iterator),
        "\t$0",
        "end"
    }
end

local abbrevs = {
    ll = "local $1 = $0",
    lt = "$1 = $0",
    rt = "return",
    wn = { "if $1 then", "\t$0", "end" },
    ff = { "function$1($2)", "\t$0", "end" },
    fl = { "function($1)", "\t$0", "end" },
    tc = { 'if type($1) == "$2" then', "\t$0", "end" },
    -- for {list,table} {values,pairs}
    Flv = loop_snippet("_, ${1:v}", "ipairs($2)"),
    Flp = loop_snippet("${1:i}, ${2:v}", "ipairs($3)"),
    Ftv = loop_snippet("_, ${1:v}", "pairs($2)"),
    Ftp = loop_snippet("${1:k}, ${2:v}", "pairs($3)"),
}

for abbr, fn in pairs(abbrevs) do
    map("ia", abbr, A(fn))
end
