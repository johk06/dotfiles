--[[ Information {{{
 This file handles the basics of unmapping unneeded mappings and has those that
 have no other place to go.

 See the other files in this directory for specialized subsets

 Unused <space> mappings:
 - i, k, v, x, y, z
 }}} ]]
-- Declarations {{{
local api = vim.api
local fn = vim.fn
local fs = require("config.lib.fs")
local utils = require("config.utils")
local ftpref = require("config.lib.ftpref")
local map = utils.map
local unmap = utils.unmap
-- }}}

-- Make the leader keys wait
map("n", "\\", "<nop>")
map("n", "<space>", "<nop>")

-- Unmap Unused {{{
map("n", "gQ", "<nop>") -- ex mode is just plain annoying

-- ZZ and ZQ are not that short and quite dangerous
map("n", "Z", "<nop>")

-- I don't like the default lsp mappings, they're a bit too long for my liking
unmap("n", "grn")              -- rename
unmap("n", "gra")              -- actions
unmap("n", "grr")              -- references
unmap("n", "gri")              -- implementation
unmap("n", "grt")              -- type definition
unmap("n", "grx")              -- codelenses
unmap({ "i", "s" }, "<Tab>")   -- snippet
unmap({ "i", "s" }, "<S-Tab>") -- snippet
-- }}}
-- Different Register Sets {{{
-- M- is rarely if ever used, I can furthermore live without this if the terminal does not support it
map({ "n", "v" }, "<M-d>", '"_d')
map({ "n", "v" }, "<M-c>", '"_c')
map({ "n", "v" }, "<M-y>", '"+y')
map({ "n", "v" }, "<M-p>", '"+p')
-- }}}
-- Shorthands for Commands {{{
map("n", "<space>w", "<cmd>write<cr>", { desc = "Write Buffer" })
map("n", "<space>W", "<cmd>wall<cr>", { desc = "Write All Buffers" })
map("n", "<space><cr>", "g<", { desc = "View Messages" })

map("n", "<space>e", function()
    local ft_map = {
        o = "org",
        m = "markdown",
        t = "typst",
        l = "lua",
        s = "sh",
        n = "",
    }
    local ft = ft_map[vim.v.register] or vim.bo.ft
    local b = api.nvim_create_buf(true, false)
    vim.bo[b].ft = ft
    require("config.utils").win_show_buf(b, {
        position = "float",
        title = "Scratch"
    })
end, { desc = "New Scratch" })
-- }}}
--[[ Change Directory {{{
 Sometimes I need a quicker way to change directory than :cd, :lcd etc
 This may benefit from being turned into a sub mode sometime (e.g. using hydra) ]]

local cdleader = "<space>."

local function get_cur_buf_parent()
    local path = fn.expand("%:p:h"):gsub("^oil://", "")
    return path
end

-- Parent
map("n", cdleader .. "h", function()
    local dir = fn.getcwd(0)
    vim.cmd.lcd(fn.fnamemodify(dir, ":h"))
end, { desc = "Directory: Go Down towards Buffer" })

-- One element right in the path
map("n", cdleader .. "l", function()
    local dir = fn.getcwd(0)
    local fpath = get_cur_buf_parent()
    if fpath ~= dir then
        local sdir = vim.split(dir, "/")
        local spath = vim.split(fpath, "/")

        local elem = 1
        while elem <= #sdir and elem <= #spath and sdir[elem] == spath[elem] do
            elem = elem + 1
        end

        vim.cmd.lcd("./" .. spath[elem])
    end
end, { desc = "Directory: Go Up" })

-- Current file parent
map("n", cdleader .. "c", function()
    vim.cmd.lcd(get_cur_buf_parent())
end, { desc = "Directory: Goto Buffer Parent" })

-- Parent of current file parent
map("n", cdleader .. "p", function()
    vim.cmd.lcd(fn.fnamemodify(get_cur_buf_parent(), ":h"))
end, { desc = "Directory: Goto Directory Parent" })

map("n", "<space>.<space>", ":cd<space>")

-- Project root
map("n", cdleader .. "r", function()
    local root = fs.get_project_root()

    vim.cmd.lcd(root)
end, { desc = "Directory: Goto Project Root" })

-- Git root
map("n", cdleader .. "g", function()
    local root = vim.fs.root(fn.getcwd(0), { ".git" })
    if root then
        vim.cmd.lcd(root)
    end
end, { desc = "Directory: Goto Git Root" })
-- }}}

--[[ Show a Table of Content, like the one in a help buffer
 based on folds, so it works for most filetypes ]]
map("n", "gO", function()
    local ufo = require("ufo")
    local buf = api.nvim_get_current_buf()

    local ok, folds = pcall(ufo.getFolds, buf, "treesitter")
    if not ok then
        folds = ufo.getFolds(buf, "indent")
    end
    local ok, markers = pcall(ufo.getFolds, buf, "marker")

    -- if we have markers, add them in
    if ok and #markers > 0 then
        vim.list_extend(folds, markers)
        table.sort(folds, function(a, b)
            return a.startLine < b.startLine
        end)
    end

    local ft = vim.bo[buf].ft

    -- remove duplicates and transform
    local seen = {}
    folds = vim.tbl_filter(function(f)
        -- for languages that commonly have identifiers followed by a { on the next line
        if vim.api.nvim_buf_get_lines(buf, f.startLine, f.startLine + 1, false)[1] == "{" then
            f.startLine = f.startLine - 1
            if f.startLine <= 0 then
                return false
            end
        end

        local show = not seen[f.startLine]
        seen[f.startLine] = true
        return show
    end, folds)

    local indents = {}
    local at_first_level = 0
    for _, fold in ipairs(folds) do
        indents[fold.startLine] = vim.fn.indent(fold.startLine + 1)
        if indents[fold.startLine] == 0 then
            at_first_level = at_first_level + 1
        end
    end

    local indent_max = (
        ftpref[ft].toc_indent
        or at_first_level < 8 and 1 or 0 -- show more detail in shorter files
    ) * vim.bo.shiftwidth

    folds = vim.tbl_filter(function(fold)
        return indents[fold.startLine] <= indent_max
    end, folds)

    local items = {}
    for _, fold in ipairs(folds) do
        table.insert(items, {
            bufnr = buf,
            lnum = fold.startLine + 1,
            end_lnum = fold.endLine + 1,
        })
    end

    fn.setloclist(0, items)
    local quicker = require("quicker")
    quicker.refresh(0)
    quicker.open { loclist = true }
end)

--[[ View information in manpage or help
 Since built in vim K is shadowed by the LSP in most cases
 this is also meant to be overridden if necessary, which is why it's here ]]
map({ "x", "n" }, "gK", function()
    local cmd
    if vim.startswith(vim.fn.expand("%:p"), vim.fn.stdpath("config")) then
        cmd = "help"
    else
        cmd = "Man"
    end

    local searchtext
    local mode = api.nvim_get_mode().mode
    if mode:find("^[vV\x16]$") then
        searchtext = table.concat(fn.getregion(fn.getpos("v"), fn.getpos("."), { type = mode }), "\n")
    else
        searchtext = fn.expand("<cword>")
    end

    utils.run_excmd(cmd, { searchtext })
end)
