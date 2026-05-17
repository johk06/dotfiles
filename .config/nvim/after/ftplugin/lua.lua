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

local abbrevs = {
    ll = "local $1 = $0",                               -- local
    lt = "$1 = $0",                                     -- let
    rt = "return",                                      -- ret
    wn = { "if $1 then", "\t$0", "end" },               -- when
    ff = { "function$1($2)", "\t$0", "end" },           -- full function (optional name)
    fl = { "function($1)", "\t$0", "end" },             -- function locale (no name)
    tc = { 'if type($1) == "$2" then', "\t$0", "end" }, -- type check
}

for abbr, fn in pairs(abbrevs) do
    map("ia", abbr, A(fn))
end
