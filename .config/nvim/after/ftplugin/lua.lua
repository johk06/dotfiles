local map = require("config.utils").ft_mapper()

map("n", "<localleader>f", [[ysa")%a:format()<Left>]], {
    remap = true,
    desc = "Lua: Format string"
})

map("n", "<localleader>p", function()
    vim.cmd([[keeppatterns s/(\s*/, /]])
    vim.cmd.normal { "ipcall(", bang = true }
end, { desc = "Lua: Protect Call" })
