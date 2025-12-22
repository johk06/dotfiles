--[[ Information {{{
 All mappings that are general purpose and active regardless of opened plugins
 This is pretty much the core of my configuration and pulls in lots of other modules

 It's grouped into rough sections based on the type of keymap or its use case(s),
 each of those should be a foldmarker section as well. }}} ]]
-- Declarations {{{
local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local ftpref = require("config.lib.ftpref")
local abbrev = utils.abbrev
local map = utils.map
local unmap = utils.unmap

local mov = utils.mode_motion
local obj = utils.mode_object

-- my own custom textobjects
local textobjs = require("config.lib.textobjs")
-- create custom operators easily
local operators = require("config.lib.operators")

-- run ex command with count
local function cmd_with_count(cmd)
    return function()
        local ok, err = pcall(api.nvim_cmd, {
            cmd = cmd,
            count = vim.v.count1,
            mods = {
            }
        }, { output = false })
        if not ok then
            utils.error("Map/" .. cmd, err, true)
        end
    end
end

local function run_cmd(cmd, args)
    local ok, err = pcall(api.nvim_cmd, {
        cmd = cmd,
        args = args,
        mods = {
        }
    }, { output = false })

    if not ok then
        utils.error("Map/" .. cmd, err, true)
    end
end
-- }}}
-- Configuration {{{
-- there still is ` for marks, ' is on the home row, soooo nice
local bufleader = "'"
-- }}}
-- Unmap Unused {{{
map("n", "gQ", "<nop>") -- ex mode is just plain annoying

-- ZZ and ZQ are not that short and often just annoying
map("n", "Z", "<nop>")

-- i don't like the lsp mappings
unmap("n", "grn")              -- rename
unmap("n", "gra")              -- actions
unmap("n", "grr")              -- references
unmap("n", "gri")              -- implementation
unmap("n", "grt")              -- type definition
unmap({ "i", "s" }, "<Tab>")   -- snippet
unmap({ "i", "s" }, "<S-Tab>") -- snippet

-- make sure that it waits
map("n", bufleader, "<nop>")
-- }}}

--[[ Quickfix- & Location list {{{
 Navigate faster with the lists
 The qflist is generally used for workspace wide things
 The loclist per each buffer/window ]]

-- Quickfix: more mappings, larger lists
map("n", "<C-j>", cmd_with_count("cnext"))
map("n", "<C-k>", cmd_with_count("cprev"))
map("n", "<space>0", "<cmd>cfirst<cr>")
map("n", "<space>$", "<cmd>clast<cr>")

-- Location: optimized for much smaller lists, usually only containing elements from a single file
map("n", "<M-j>", cmd_with_count("lnext"))
map("n", "<M-k>", cmd_with_count("lprev"))

-- Reuse [g]o [l]ist prefix, Uppercase for qflist, for more uses see ./lua/config/lsp.lua
-- Diagnostics
map("n", "glE", function() vim.diagnostic.setqflist { open = true } end, { desc = "Qflist: Diagnostics ([E]rrors)" })
map("n", "gle", function() vim.diagnostic.setloclist { open = true } end, { desc = "Loclist: Diagnostics ([E]rrors)" })

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
    run_cmd("lvimgrep", { "/" .. search .. "/gj", "%" })
end, { desc = "Loclist: List Search" })

map("n", "gl?", function()
    local search = fn.getreg("/")
    run_cmd("vimgrep", { "/" .. search .. "/gj", "**" })
end, { desc = "Qflist: List Search" })

-- toggle the lists, like other buffer mappings
map("n", bufleader .. "q", function()
    require("quicker").toggle { min_height = 8 }
end, { desc = "Qflist: Show" })
map("n", bufleader .. "l", function()
    require("quicker").toggle { min_height = 8, loclist = true }
end, { desc = "Loclist: Show" })

-- vertical view
local vertical_qf_wincfg = {
    split = "left",
    width = 72,
    vertical = true
}

map("n", bufleader .. "Q", function()
    local qfwin = fn.getqflist { winid = true }.winid
    if qfwin == 0 then
        require("quicker").open()
        qfwin = fn.getqflist { winid = true }.winid
    end

    api.nvim_win_set_config(qfwin, vertical_qf_wincfg)
    vim.wo[qfwin][0].number = true
end, { desc = "Qflist: Vertical" })

map("n", bufleader .. "L", function()
    local locwin = fn.getloclist(0, { winid = true }).winid
    if locwin == 0 then
        require("quicker").open { loclist = true }
        locwin = fn.getloclist(0, { winid = true }).winid
    end

    api.nvim_win_set_config(locwin, vertical_qf_wincfg)
    vim.wo[locwin][0].number = true
end, { desc = "Loclist: Vertical" })

-- }}}
-- Commands {{{
map("n", "<space>m", function()
    vim.cmd [[
    write
    silent make
    cwindow
    ]]
    require("quicker").refresh()
end, { desc = "Make" })

map("n", "<space>w", "<cmd>write<cr>", { desc = "Write Buffer" })
map("n", "<space>W", "<cmd>wall<cr>", { desc = "Write All Buffers" })
-- }}}
-- Folds {{{

--[[ focus the current fold
 - zM: close all folds
 - zO: open the current one, recursively
 - [z: move to the top of it
 - zt: place it at the top of the screen
 the j is required so that this applies when on the fold start ]]
map("n", "<Tab>", "zMzOj[zzt", { remap = true --[[ is required so ufo applies ]] })
-- }}}
-- Buffers & Windows {{{
-- faster alternate file, mnemonic: [s]econd, also allows remapping <C-6>
map("n", "<C-s>", "<cmd>b #<cr>")

-- move linearly
map("n", bufleader .. "j", "<cmd>bnext<cr>", { desc = "Buffer: Next" })
map("n", bufleader .. "k", "<cmd>bprev<cr>", { desc = "Buffer: Prev" })

-- same for tabs
map("n", bufleader .. "J", "gt", { desc = "Tab: Next" })
map("n", bufleader .. "K", "gT", { desc = "Tab: Prev" })

local function get_buf_idx()
    local target
    local count = vim.v.count
    if count == 0 then
        target = api.nvim_get_current_buf()
    else
        target = Bufs_for_idx[count]
    end
    if not target or not api.nvim_buf_is_valid(target) then
        utils.error("Mappings", "No Buffer #" .. count)
        return
    end

    return target
end

-- go to the buffer given in v:count
local goto_buf = function()
    if vim.v.count == 0 then
        vim.cmd.bnext()
        return
    end

    local target = get_buf_idx()
    if not target then return end

    local win = fn.bufwinid(target)
    if win > 0 then
        api.nvim_set_current_win(win)
        return
    end

    local ok = pcall(api.nvim_set_current_buf, target)
    if not ok then
        vim.cmd.bprevious()
    end
end

map("n", bufleader .. bufleader, goto_buf, { desc = "Buffer: Show" })

---@param dir config.win.position
---@param opts config.win.opts?
local function open_buf_in(dir, opts)
    return function()
        local target = get_buf_idx()
        if not target then return end

        utils.win_show_buf(target, vim.tbl_extend("force", { position = dir }, opts or {}))
    end
end

-- show a buffer by its index in the statusbar
-- 'v, 's are equivalent to <C-w>v and <C-w>s
map("n", bufleader .. "v", open_buf_in("vertical"), { desc = "Buffer: Show vsplit" })
map("n", bufleader .. "s", open_buf_in("horizontal"), { desc = "Buffer: Show split" })
map("n", bufleader .. "V", open_buf_in("vertical", { direction = "left" }), { desc = "Buffer: Show vsplit (before)" })
map("n", bufleader .. "S", open_buf_in("horizontal", { direction = "above" }), { desc = "Buffer: Show split (before)" })
map("n", bufleader .. "t", open_buf_in("tab"), { desc = "Buffer: Show tab" })
map("n", bufleader .. "f", open_buf_in("float"), { desc = "Buffer: Show float" })
map("n", bufleader .. "a", open_buf_in("autosplit"), { desc = "Buffer: Show auto" })
map("n", bufleader .. "r", open_buf_in("replace"), { desc = "Buffer: Replace current" })

local delete_buffer = function(buf)
    local ok = pcall(api.nvim_buf_delete, buf, {})
    if not ok then
        local short = Short_for_bufs[buf]
        local name = utils.format_buf_name(buf) or "[-]"
        local msg = ("Buffer %s%d (%s) is modified, force delete? [y/N] "):format(short and "#" or ".", short, name)
        local response = vim.fn.input { prompt = msg }
        if response:lower() == "y" then
            api.nvim_buf_delete(buf, { force = true })
        end
    end
end

-- delete buffer
map("n", bufleader .. "d", function()
    local target = get_buf_idx()
    if not target then return end

    delete_buffer(target)
end, { desc = "Buffer: Delete" })

-- close the first window that the buffer is shown in
map("n", bufleader .. "h", function()
    local target = get_buf_idx()
    if not target then return end

    local win = fn.bufwinid(target)
    if win == -1 then
        utils.error("Mappings", "No open Window for Buffer ")
        return
    end
    api.nvim_win_close(win, false)
end, { desc = "Buffer: Hide win" })

-- clear hidden buffers
map("n", bufleader .. "C", function()
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if vim.bo[buf].buflisted and fn.bufwinid(buf) == -1 then
            delete_buffer(buf)
        end
    end
end, { desc = "Buffer: Clear hidden" })

---run cmd with the effective tab target as an argument
local function indexed_tab_command(cmd)
    local target
    local count = vim.v.count
    if count == 0 then
        target = ""
    else
        target = Tabs_for_idx[count]
    end

    vim.cmd(cmd .. " " .. target)
end

local function get_tab_idx()
    local target
    local count = vim.v.count
    if count == 0 then
        target = api.nvim_get_current_tabpage()
    else
        target = Tabs_for_idx[count]
    end
    if not target or not api.nvim_tabpage_is_valid(target) then
        utils.error("Mappings", "No Tab #" .. count)
        return
    end

    return target
end

map("n", bufleader .. "H", function() indexed_tab_command("tabclose") end, { desc = "Tab: Hide" })

--[[ Fully delete all of a tab's buffers
Useful for things like <space>g<C-h> from ./lua/plugins/git.lua ]]
map("n", bufleader .. "D", function()
    local tab = get_tab_idx()
    if not tab then
        return
    end

    local seen = {}
    local bufs = vim.tbl_filter(function(buf)
        local keep = not seen[buf]
        seen[buf] = true
        return keep and api.nvim_buf_is_valid(buf)
    end, vim.tbl_map(function(win)
        return api.nvim_win_get_buf(win)
    end, api.nvim_tabpage_list_wins(tab)))

    for _, buf in ipairs(bufs) do
        delete_buffer(buf)
    end
end, { desc = "Tab: Delete recursively" })
-- }}}
-- Improved Builtin Mappings {{{

-- make them wait until I press another key
-- most useful for leaders like this
map("n", "\\", "<nop>")
map("n", "<space>", "<nop>")

-- keep jumplist intact for {}, it's a relatively small motion
map(mov, "{", function() return "<cmd>keepj normal!" .. vim.v.count1 .. "{<cr>" end, { remap = false, expr = true })
map(mov, "}", function() return "<cmd>keepj normal!" .. vim.v.count1 .. "}<cr>" end, { remap = false, expr = true })

-- center the screen for jumps
map(mov, "<C-o>", "<C-o>zz")
map(mov, "<C-i>", "<C-i>zz")

-- those are hard to reach by default,
-- I do not use Low and High for navigation and even rarer in o-pending mode
-- also kinda logical, a stronger version of lh
map(mov, "L", "$")
map(mov, "H", "^") -- 0 is significantly less useful than ^ and easier to reach as well

-- keep the old ones around though
map(mov, "gL", "L")
map(mov, "gH", "H")

-- like (now-default) []<space>, but for characters inside a line, e.g. to separate words
local insert_spaces = function(direction)
    local spaces = (" "):rep(vim.v.count1)
    local cursor = api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = direction < 0 and cursor[2] or cursor[2] + 1
    api.nvim_buf_set_text(0, row, col, row, col, { spaces })
end

map("n", "<<space>", function() insert_spaces(-1) end)
map("n", "><space>", function() insert_spaces(1) end)
-- }}}
-- Set options {{{
-- [c]onfigure
map("n", "<space>cs", "<cmd>set spell!<cr>", { desc = "Toggle 'spell'" })
map("n", "<space>cg", "<cmd>set spell spl=de<cr>", { desc = "German spelling" })
map("n", "<space>ce", "<cmd>set spell spl=en<cr>", { desc = "English spelling" })
map("n", "<space>cl", "<cmd>set list!<cr>", { desc = "Toggle 'list'" })
map("n", "<space>cw", "<cmd>set wrap!<cr>", { desc = "Toggle 'wrap'" })

map("n", "<space>cW", function()
    vim.o.textwidth = vim.v.count * 10
end, { desc = "Set Width" })

map("n", "<space>c|", function()
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

map("n", "<space>ci", function()
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

map("n", "<space>cc", function()
    vim.wo.conceallevel =
        vim.v.count ~= 0 and vim.v.count or (vim.wo.conceallevel == 0 and 2 or 0)
end, { desc = "Toggle Conceal" })

map("n", "<space>cC", function()
    local cur = vim.opt_local.concealcursor:get()
    if cur.n and cur.i then
        vim.wo.concealcursor = ""
    elseif cur.n then
        vim.wo.concealcursor = "nvic"
    else
        vim.wo.concealcursor = "n"
    end
end, { desc = "Cycle Concealcursor" })

map("n", "<space>cd", function()
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
-- }}}
-- Rethink the macro system & other register improvements {{{
-- use "reg, like other vim commands, defaulting to "q
local getmacroreg = function()
    local r = vim.v.register
    return r ~= '"' and r or "q"
end

map({ "n", "x" }, "<C-q>", function()
    if fn.reg_recording() ~= "" then
        return "q"
    else
        return "q" .. getmacroreg()
    end
end, { expr = true })

-- specify registers the same way for @
map({ "n", "x" }, "@", "<nop>")
map({ "n", "x" }, "@", function()
    if api.nvim_get_mode().mode:lower() == "v" then
        return ("\x1b<cmd>'<,'>normal! @%s<cr>"):format(getmacroreg())
    else
        return "@" .. getmacroreg()
    end
end, { expr = true })

-- this now frees up q to close windows and cycle
-- additionally this is the norm for lots of plugin's floating windows as well, so this helps avoid surprises
map("n", "q", function()
    local ok = pcall(vim.cmd.close)
    if not ok then
        vim.cmd.bnext()
    end
end)


local edit_register = require("config.edit-register")

map("n", "cq", function()
    edit_register.edit_macro(getmacroreg())
end, { desc = "Macro: Change" })
map("n", "yq", function()
    edit_register.load_macro(getmacroreg())
end, { desc = "Macro: Load" })
map("n", "dq", function()
    edit_register.save_macro(getmacroreg())
end, { desc = "Macro: Define" })
-- }}}
-- Abbreviations {{{

-- I probably never will actually use :file
-- If I need it, i can survive typing the full name
abbrev("c", "f", "find")
abbrev("c", "vf", "vertical sf") -- much shorter, much more useful

-- often useful for one-off commands
abbrev("c", "vt", "vertical terminal")
abbrev("c", "st", "horizontal terminal")
-- }}}
-- Terminal {{{
local terminal = require("config.terminal")

local termleader = "<space>t"
map("n", termleader .. "s", function() terminal.open_term { position = "horizontal" } end)
map("n", termleader .. "v", function() terminal.open_term { position = "vertical" } end)
map("n", termleader .. "r", function() terminal.open_term { position = "replace" } end)
map("n", termleader .. "f", function() terminal.open_term { position = "float" } end)
map("n", termleader .. "a", function() terminal.open_term { position = "autosplit" } end)
map("n", termleader .. "t", function() terminal.open_term { position = "autosplit" } end)

-- lf integrates nicely by calling nvr when it needs to open stuff
map("n", termleader .. "l", function()
    terminal.open_term {
        position = "autosplit",
        cmd = { "lf" }
    }
end)

-- various other useful programs
map("n", termleader .. "p", function()
    terminal.open_term {
        position = "autosplit",
        cmd = { "python" },
        title = "python"
    }
end)
map("n", termleader .. "q", function()
    terminal.open_term {
        position = "autosplit",
        cmd = { "qalc" },
        title = "qalc",
        size = { 60, 20 },
    }
end)

-- exit terminal mode with a single chord instead of 2
map("t", "<M-Esc>", "<C-\\><C-n>")
map("t", "<M-C-w>", "<C-\\><C-n><C-w>")
-- }}}
-- Insert Mode {{{
--[[ Why would I want to do smth so un-vimmy?
 Well, on my keyboard tapping L/R Shift yields BS/Del,
 so tapping one shift key while holding the other makes sense ]]
map("i", "<S-BS>", "<C-w>")
map("i", "<S-Del>", "<c-o>\"_dw")

-- go to basically any character in the line in insert mode
-- navigation further than that needs normal mode anyways
map("i", "<C-f>", "<C-o>f", { remap = true })
map("i", "<C-b>", "<C-o>T", { remap = true })

-- quick way to trigger things like ]a in insert mode
-- useful example: <C-.>a to go to the next argument
map("i", "<C-.>", "<C-o>]", { remap = true })
map("i", "<C-,>", "<C-o>[", { remap = true })

-- the same thing for the repetition keys
map("i", "<C-.><C-.>", "<C-o>;", { remap = true })
map("i", "<C-,><C-,>", "<C-o>,", { remap = true })

---@param char string
local toggle_char_at_eol = function(char)
    local line = api.nvim_get_current_line()
    local old_char = line:match("(" .. vim.pesc(char) .. "*)$")
    local lnum = api.nvim_win_get_cursor(0)[1]
    api.nvim_buf_set_text(0, lnum - 1, #line - #old_char, lnum - 1, #line, {
        #old_char == 0 and char or ""
    })

    return false
end

-- TODO: evaluate whether this even makes sense
map("i", "<M-;>", function() toggle_char_at_eol(";") end)
map("i", "<M-,>", function() toggle_char_at_eol(",") end)

--[[ Leftover keys looking for a mapping
- <C-z>
-- <C-m> maybe, may conflict with <cr>
}}} ]]
--[[ Command Mode {{{
All of these are just shortcuts for simple text insertions for now
Some highlights:
- Fast inserting of common pattern characters in search mode
]]

---@param keys string
---@param rhs string|function
local map_search = function(keys, rhs)
    map("c", keys, function()
        local cmdtype = fn.getcmdtype()
        local cmdline = fn.getcmdline()
        if cmdtype == "/" or cmdtype == "?"
            or cmdline:match("^%A*[sgv]") then
            if type(rhs) == "function" then
                return rhs()
            else
                return rhs
            end
        else
            return keys
        end
    end, { expr = true })
end

map_search("<M-space>", "\\s*")
map_search("<C-space>", "\\s\\+")

map_search("<M-w>", "\\<\\><Left><Left>")
map_search("<M-g>", "\\(\\)<Left><Left>")
map_search("<M-/>", function()
    local cmdline = fn.getcmdline()
    local replaced = cmdline:gsub("/*$", "/")
    fn.setcmdline(replaced, #replaced + 1)
end)

-- cycle magic: default -> very -> plain -> default
map_search("<M-m>", function()
    local cmdline = fn.getcmdline()
    local replacement
    local modifier = cmdline:match("^\\([mMvV])")
    if not modifier then
        replacement = "\\v" .. cmdline
    elseif modifier == "m" or modifier == "v" then
        replacement = "\\V" .. cmdline:sub(3)
    else
        replacement = cmdline:sub(3)
    end
    fn.setcmdline(replacement)
end)
-- }}}
-- Snippets {{{
-- move between snippet fields
map({ "n", "s", "i" }, "<M-space>", function() vim.snippet.jump(1) end)
map({ "n", "s", "i" }, "<C-space>", function() vim.snippet.jump(-1) end)
-- }}}
--[[ Textobjects & Motions {{{
 Textobjects and motions are the heart of Vim, so it makes sense to optimize them more than almost everything else.
 This section has both abbreviations for, as well as new, motions and textobjects(mostly). ]]

-- % is annoying to press
-- [m]atching, this may take some inspiration from helix :)
map(obj, "m", "<plug>(matchup-%)")
map(obj, "im", "<plug>(matchup-i%)")
map(obj, "am", "<plug>(matchup-a%)")

--[[ turn the *Ncgn pattern into a nice and small textobject
 Operators that don't invalidate the match require `n` afterwards to move the cursor.
 So anything that deletes, changes etc is best.
 Then continue hitting `.` to apply or `n` to go to the next match.
 This way this can work almost like :%s///c, but for arbitrary operations
 Examples:
 - gs* to replace each occurrence with register. ]]
map("o", "*", function()
    return "\x1b*N" .. vim.v.operator .. "gn"
end, { expr = true })
map("o", "#", function()
    return "\x1b#N" .. vim.v.operator .. "gN"
end, { expr = true })

-- less annoying to type
map(obj, "iq", [[i"]])
map(obj, "aq", [[a"]])
map(obj, "iQ", [[i']])
map(obj, "aQ", [[a']])

--[[ target the area of a diagnostic with a textobject
 `id` matches every type
 Examples:
 - cid_<esc> to change an "unused variable" ]]
map(obj, "id", textobjs.diagnostic)
map(obj, "iDe", textobjs.diagnostic_error)
map(obj, "iDw", textobjs.diagnostic_warn)
map(obj, "iDi", textobjs.diagnostic_info)
map(obj, "iDh", textobjs.diagnostic_hint)

--[[ indents, very useful for python or other indent based languages
 `a` includes one line above and below, except for filetypes like python or
 lisps where only the above line is included by default.
 `aI` always includes the line below too, even for python et cetera, useful for
 object literals like dicts or lists or nested languages

 If present, v:count specifies the amount of indent levels instead of the current cursor position
 this is particularly useful for languages like python where
 c1ii comes to mean "change in the topmost scope"
 d2ai for example then means "delete this method"
 NOTE: this uses shiftwidth, so it's not 100% reliable for files
 that do not have the same shiftwidth or variations in its indent width ]]
map(obj, "ii", textobjs.indent_inner)
map(obj, "ai", textobjs.indent_outer)
map(obj, "aI", textobjs.indent_outer_with_last)

-- a foldmarker section - *not* a fold
map(obj, "iz", textobjs.foldmarker_inner)
map(obj, "az", textobjs.foldmarker_outer)

-- snake_case or kebab-case sub-word
map(obj, "i-", textobjs.create_pattern_obj("([-_]?)%w+([-_]?)"))
map(obj, "a-", textobjs.create_pattern_obj("()[-_]?%w+[-_]?()"))

-- object chain, most languages, NOTE: does not include lua `:`
-- This can also be taken as a generic identifier object
-- For languages that do not include e.g. -
map(obj, "i.", textobjs.create_pattern_obj("()[%w._]+()"))
map(obj, "a.", textobjs.create_pattern_obj("()%s*[%w._]+%s*()"))

-- path component, last / is optional
map(obj, "i/", textobjs.create_pattern_obj("(/)[^/]+(/?)"))
map(obj, "a/", textobjs.create_pattern_obj("/()[^/]+()/?"))


--[[ Numbers
Inner variant preserves the sign of the number as well as any potential type prefix (0x) etc ]]
map(obj, "in", textobjs.create_pattern_obj {
    "([+-]?0x)%x+()",    -- decimal int
    "([+-]?0b)[01]+()",  -- binary int
    "([+-]?0o)[0-7]+()", -- octal int
    "([+-]?)%d+%.%d*()", -- decimal float
    "([+-]?)%d+()",      -- decimal int
})
map(obj, "an", textobjs.create_pattern_obj {
    "()[+-]?0x%x+()",    -- decimal int
    "()[+-]?0b[01]+()",  -- binary int
    "()[+-]?0o[0-7]+()", -- octal int
    "()[+-]?%d+%.%d*()", -- decimal float
    "()[+-]?%d+()",      -- decimal int
})

-- entire buffer, mirroring the motions that would achieve the same thing: VgG
map(obj, "gG", textobjs.entire_buffer)

-- a C-style variable value; ignore visual mode since = is useful there
-- this is a heuristic, for "proper variable" declarations use `iv` from treesitter
map("o", "=", textobjs.variable_value)
-- }}}
--[[ Custom Operators {{{
 Operators are important as well
 This section mostly has operators where no plugin has managed to satisfy me (yet)]]

--[[ Command in Region
 Open a cmdline in a region specified by a textobject or motion
 Allows repeating commands like they're regular mappings
 mostly useful with things like :g and :s ]]
---@diagnostic disable-next-line: unused-local
operators.map_function("g:", function(mode, region, extra)
    if extra.repeated then
        ---@diagnostic disable-next-line: param-type-mismatch
        local ok, err = pcall(vim.cmd, string.format("%d,%d%s", region[1][1], region[2][1], extra.saved.cmd))
        if not ok and err then
            vim.notify(tostring(err), vim.log.levels.ERROR)
        end
    else
        local cmdstr = string.format(":%d,%d", region[1][1], region[2][1])
        api.nvim_feedkeys(cmdstr, "n", false)

        api.nvim_create_autocmd("CmdlineLeave", {
            once = true,
            callback = function()
                local command_line = fn.getcmdline()
                local command = command_line:match("^%d+,%d+(.*)$")
                if not command then
                    command = ""
                end
                extra.saved.cmd = command
            end
        })
    end
end)

---@param lines string[]
---@param count integer
---@return string[]
local multiply_lines = function(lines, count)
    local ret = {}
    if count <= 1 then
        return lines
    end
    for _ = 1, count do
        vim.list_extend(ret, lines)
    end

    return ret
end

---@type config.op.operator_func
local multiply_operator = function(mode, region, extra)
    local before = extra.args and extra.args.before or false
    local target = before and region[1] or region[2]

    if mode == "char" and region[1][1] == region[2][1] then
        local text = operators.get_region(mode, region)
        local sel = text[1]
        if not (sel:match("%s$") or sel:match("^%s") or sel:match("%W$") or sel:match("^%W")) then
            if before then
                sel = sel .. " "
            else
                sel = " " .. sel
            end
        end
        local to_insert = { sel:rep(math.max(1, extra.hijacked_count)) }

        local row = target[1] - 1
        local col = target[2] + (before and 0 or 1)
        api.nvim_buf_set_text(0, row, col, row, col, to_insert)
    else
        local text = operators.get_region("line", region)
        local to_insert = multiply_lines(text, extra.hijacked_count)
        local line = before and target[1] - 1 or target[1]
        api.nvim_buf_set_lines(0, line, line, false, to_insert)
    end
end

--[[ Duplicate elements
 [g]o [m]ultiply
 uses the first count as an indication of how often to multiply
 e.g. 2gmiw -> duplicates the current word twice
 If the object to multiply is an inline word and does not have a separator,
 a space will be added.
 The capital version puts the duplicate before the cursor instead of after it.
 Examples:
 - gmaa to duplicate an argument to a function, e.g. type `NULL` once and then gmaa it
 - gmm followed by an edit to create a slightly different copy of the current line
   As many people correctly pointed out, yyp not leaving the cursor in place makes this more difficult with builtins ]]
operators.map_function("gm", multiply_operator, { hijack_count = true })
operators.map_function("gM", multiply_operator, { hijack_count = true }, { before = true })

--[[ Sort a range of lines/elements
In a single line: use commas
Otherwise: sort lines
Anything that this can't do should be done with :!sort anyways ]]
operators.map_function("g=", function(mode, region, _)
    local text = operators.get_region(mode, region)
    local items
    local comma_separated = #text == 1
    if comma_separated then
        items = vim.split(text[1], ",")
    else
        items = text
    end

    local whites = {}
    local texts = {}
    for _, item in ipairs(items) do
        local leading_white = item:match("^(%s*)")
        local trailing_white = item:match("(%s*)$")
        table.insert(whites, { leading_white, trailing_white })
        table.insert(texts, vim.trim(item))
    end

    table.sort(texts)

    local replacements = {}
    for i, white in ipairs(whites) do
        table.insert(replacements,
            white[1] .. texts[i] .. white[2]
        )
    end

    if comma_separated then
        operators.set_region("char", region, { table.concat(replacements, ",") })
    else
        operators.set_region(mode, region, replacements)
    end
end)
-- }}}
--[[ Change Directory {{{
 Sometimes I need a quicker way to change directory than :cd, :lcd etc
 This may benefit from being turned into a sub mode sometime (e.g. using hydra) ]]
local cdleader = "<space>."

local function get_cur_buf_parent()
    local path = fn.expand("%:p:h"):gsub("^oil://", "")
    return path
end

-- goto parent
map("n", cdleader .. "h", function()
    local dir = fn.getcwd(0)
    vim.cmd.lcd(fn.fnamemodify(dir, ":h"))
end, { desc = "Directory: Go Down towards Buffer" })

-- go one element right in current files path
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

-- go to current files dir
map("n", cdleader .. "c", function()
    vim.cmd.lcd(get_cur_buf_parent())
end, { desc = "Directory: Goto Buffer Parent" })

-- go to current files dir
map("n", cdleader .. "p", function()
    vim.cmd.lcd(fn.fnamemodify(get_cur_buf_parent(), ":h"))
end, { desc = "Directory: Goto Directory Parent" })

map("n", "<space>.<space>", ":cd<space>")

local get_best_root = function()
    local root
    local clients = vim.lsp.get_clients { bufnr = api.nvim_get_current_buf() }
    if #clients == 0 then
        clients = vim.lsp.get_clients {}
    end
    if #clients > 0 then
        root = clients[1].root_dir
    end

    if not root then
        root = vim.fs.root(fn.getcwd(0), { ".git", "Makefile" })
    end

    return root
end

-- go to project root
map("n", cdleader .. "r", function()
    local root = get_best_root()

    if root then
        vim.cmd.lcd(root)
    end
end, { desc = "Directory: Goto Project Root" })

-- go to git root
map("n", cdleader .. "g", function()
    local root = vim.fs.root(fn.getcwd(0), { ".git" })
    if root then
        vim.cmd.lcd(root)
    end
end, { desc = "Directory: Goto Git Root" })
-- }}}
--[[ Table of Content {{{
 like the one in a help buffer
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

--[[ view information in manpage or help
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

    run_cmd(cmd, { searchtext })
end)
-- }}}
