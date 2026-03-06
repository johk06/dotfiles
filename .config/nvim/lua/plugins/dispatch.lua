--[[ Why something so old?
 It does very little.
 "Modern" alternatives like https://github.com/stevearc/overseer.nvim do
 everything up to and including parsing Microsoft's weird build specification.
 Additionally they have various new pieces of UI that do not necessarily make
 sense with my approach. (Task lists, "editors" and other things)

 If I need a seriously complicated command, just using the shell is easier than
 learning a new interface.

 Basic workflow:
 - <space>b to build basically anything, with `make` adding a v:count makes it clean first
 - If I am interested in the output: <space>mo
]]

local M = {
    "tpope/vim-dispatch"
}

M.init = function()
    vim.g.dispatch_no_maps = true

    local utils = require("config.utils")

    utils.map("n", "<space>mi", ":Make<space>", { desc = "Make (interactive)" })
    utils.map("n", "<space>md", ":Dispatch<space>", { desc = "Make: dispatch" })
    utils.map("n", "<space>ma", "<cmd>AbortDispatch<cr>", { desc = "Make: abort" })
    utils.map("n", "<space>mc", "<cmd>Make! clean<cr>", { desc = "Make: clean" })
    utils.map("n", "<space>mo", "<cmd>Copen<cr>", { desc = "Make: open" })
    utils.map("n", "<space>mv", "<cmd>Make<cr>", { desc = "Make: verbose" })

    utils.map("n", "<space>b", function()
        if vim.o.makeprg == "make" and vim.v.count ~= 0 then
            vim.cmd.Make { "clean", bang = true }
        end
        vim.cmd.Make { bang = true }
    end, { desc = "Build: do what I mean" })
end

return M
