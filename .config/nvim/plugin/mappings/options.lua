--[[ Synopsis: Adjust Options on the fly {{{
 Using a [c]onfigure prefix
]]

local utils = require("config.utils")
local map = utils.map
-- }}}

map("n", "<space>cs", "<cmd>set spell!<cr>", { desc = "Toggle 'spell'" })
map("n", "<space>cg", "<cmd>set spell spl=de<cr>", { desc = "German spelling" })
map("n", "<space>ce", "<cmd>set spell spl=en<cr>", { desc = "English spelling" })
map("n", "<space>cl", "<cmd>set list!<cr>", { desc = "Toggle 'list'" })
map("n", "<space>cw", "<cmd>set wrap!<cr>", { desc = "Toggle 'wrap'" })
map("n", "<space>cW", function() -- 'textwidth'
    vim.o.textwidth = vim.v.count * 10
end, { desc = "Set Width" })
map("n", "<space>c|", function() -- 'colorcolumn'
    if vim.o.colorcolumn == "" then
        if vim.o.textwidth ~= 0 then
            vim.o.colorcolumn = "+1"
        else
            if vim.o.columns >= 120 then
                vim.o.colorcolumn = "120"
            else
                vim.o.colorcolumn = "80"
            end
        end
    else
        vim.o.colorcolumn = ""
    end
end, { desc = "Cycle 'colorcolumn'" })
map("n", "<space>ci", function() -- 'shiftwidth'
    local needs_reindent = false
    local count = vim.v.count
    if count > 0 then
        vim.bo.expandtab = true
        needs_reindent = count ~= vim.bo.shiftwidth
        vim.bo.shiftwidth = count
    else
        vim.bo.expandtab = not vim.bo.expandtab
    end

    vim.cmd("retab!")
    if needs_reindent then
        vim.cmd("normal! mzgg=G'z")
    end
end, { desc = "Cycle Indent" })
map("n", "<space>cc", function() -- 'conceallevel'
    vim.wo.conceallevel =
        vim.v.count ~= 0 and vim.v.count or (vim.wo.conceallevel == 0 and 2 or 0)
end, { desc = "Toggle Conceal" })
map("n", "<space>cC", function() -- 'concealcursor'
    local cur = vim.opt_local.concealcursor:get()
    if cur.n and cur.i then
        vim.wo.concealcursor = ""
    elseif cur.n then
        vim.wo.concealcursor = "nvic"
    else
        vim.wo.concealcursor = "nc"
    end
end, { desc = "Cycle Concealcursor" })
map("n", "<space>cd", function() -- 'number', 'foldcolumn' and 'relativenumber'
    if vim.wo.number then
        vim.wo.number = false
        vim.wo.foldcolumn = "0"
        vim.wo.relativenumber = false
    else
        vim.wo.number = true
        vim.wo.foldcolumn = "1"
        vim.wo.relativenumber = true
    end
end, { desc = "Change Decoration" })
