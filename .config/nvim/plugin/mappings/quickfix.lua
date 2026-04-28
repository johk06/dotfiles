--[[ Synopsis: Provide shortcuts for most quickfix functionality {{{
 The qflist is generally used for workspace wide things
 The loclist per each buffer/window ]]

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local map = utils.map
local cmd_with_count = utils.cmd_with_count
-- }}}

--[[ Quickfix: More mappings, larger lists {{{
]]
map("n", "<C-j>", cmd_with_count("cnext"))
map("n", "<C-k>", cmd_with_count("cprev"))
map("n", "<space>n", cmd_with_count("cnfile"))
map("n", "<space>N", cmd_with_count("cpfile"))
map("n", "<space>0", "<cmd>cfirst<cr>")
map("n", "<space>$", "<cmd>clast<cr>")
-- }}}
--[[ Location: optimized for much smaller lists {{{
 it usually only containing elements from a single file 
]]
map("n", "<M-j>", cmd_with_count("lnext"))
map("n", "<M-k>", cmd_with_count("lprev"))
-- }}}
--[[ [g]et [l]isting {{{
 Reuse prefix from config/lsp.lua, uppercase for Quickfix
]]

-- Diagnostics, specify kind via register if needed
---@param setter string
local open_with_optional_severity = function(setter)
    return function()
        local severity = vim.diagnostic.severity
        local kind = ({
            e = severity.ERROR,
            w = severity.WARN,
            i = severity.INFO,
            h = severity.HINT,
        })[vim.v.register]
        vim.diagnostic[setter] { open = true, severity = kind }
    end
end
map("n", "glE", open_with_optional_severity("setqflist"), { desc = "Qflist: Errors" })
map("n", "gle", open_with_optional_severity("setloclist"), { desc = "Loclist: Errors" })

-- list all TODOs, only when followed by a description
map("n", "glT", [[<cmd>silent grep! '\b(TODO\|HACK\|FIXME):'|cwin<cr>]], { desc = "Qflist: List TODOs" })
map("n", "glt", [[<cmd>silent lvimgrep! /\<\%(TODO\|HACK\|FIXME\):/ %|lwin<cr>]], { desc = "Loclist: List TODOs" })

local spell_severity_mapping = {
    ["bad"] = "E",
    ["caps"] = "W",
    ["rare"] = "H",
    ["local"] = "I"
}

local get_spelling_errors = function()
    if not vim.wo.spell then
        utils.error("Spell", "'spell' is not set")
        return {}
    end

    ---@type vim.quickfix.entry
    local entries = {}

    local save = api.nvim_win_get_cursor(0)

    local bufnr = api.nvim_get_current_buf()
    local linecount = api.nvim_buf_line_count(0)
    -- TODO: find a better way to get spelling errors
    for i = 1, linecount do
        api.nvim_win_set_cursor(0, { i, 0 })

        local last_col = 0
        while true do
            local badword = fn.spellbadword()
            if badword[1] == "" then
                break
            end

            local cursor = api.nvim_win_get_cursor(0)
            if last_col == cursor[2] then
                break
            end
            last_col = cursor[2]
            api.nvim_win_set_cursor(0, { i, cursor[2] + #badword[1] + 1 })

            ---@type vim.quickfix.entry
            local entry = {
                bufnr = bufnr,
                text = badword[1],
                col = last_col + 1,
                lnum = i,
                type = spell_severity_mapping[badword[2]]
            }
            table.insert(entries, entry)
        end
    end

    api.nvim_win_set_cursor(0, save)

    return entries
end

-- list spelling errors in the current file
map("n", "gls", function()
    fn.setloclist(0, get_spelling_errors())
end, { desc = "Loclist: Spelling" })

-- and for all buffers
map("n", "glS", function()
    local errors = {}
    for _, b in ipairs(api.nvim_list_bufs()) do
        local errs = api.nvim_buf_call(b, function()
            local spell_save = vim.opt_local.spell
            vim.opt_local.spell = true
            local ret = get_spelling_errors()
            vim.opt_local.spell = spell_save
            return ret
        end)

        vim.list_extend(errors, vim.tbl_map(function(value)
            value.bufnr = b
            return value
        end, errs))
    end

    fn.setqflist(errors)
end, { desc = "Qflist: Spelling" })

-- expand current search to quickfix
map("n", "gl/", function()
    local search = fn.getreg("/")
    utils.run_excmd("lvimgrep", { "/" .. search .. "/gj", "%" })
end, { desc = "Loclist: List Search" })

map("n", "gl?", function()
    local search = fn.getreg("/")
    utils.run_excmd("vimgrep", { "/" .. search .. "/gj", "**" })
end, { desc = "Qflist: List Search" })
-- }}}

-- Toggle the lists, like any other buffer mapping
map("n", "'q", function()
    require("quicker").toggle { min_height = 8 }
end, { desc = "Qflist: Show" })
map("n", "'l", function()
    require("quicker").toggle { min_height = 8, loclist = true }
end, { desc = "Loclist: Show" })

-- Same, but vertical, mirroring mappings/buffers.lua
local vertical_qf_wincfg = {
    split = "left",
    width = 72,
    vertical = true
}

map("n", "'Q", function()
    local qfwin = fn.getqflist { winid = true }.winid
    if qfwin == 0 then
        require("quicker").open()
        qfwin = fn.getqflist { winid = true }.winid
    end

    api.nvim_win_set_config(qfwin, vertical_qf_wincfg)
    vim.wo[qfwin][0].number = true
end, { desc = "Qflist: Vertical" })
map("n",  "'L", function()
    local locwin = fn.getloclist(0, { winid = true }).winid
    if locwin == 0 then
        require("quicker").open { loclist = true }
        locwin = fn.getloclist(0, { winid = true }).winid
    end

    api.nvim_win_set_config(locwin, vertical_qf_wincfg)
    vim.wo[locwin][0].number = true
end, { desc = "Loclist: Vertical" })
