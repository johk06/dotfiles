--[[ Information {{{
All mappings that are general purpose and active regardless of opened plugins
}}} ]]

-- Declarations {{{
local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local ftpref = require("config.ftpref")
local abbrev = utils.abbrev
local map = utils.map
local unmap = utils.unmap
local ui = require("config.ui")
local hlns = ui.ns

local mov = utils.mode_motion
local obj = utils.mode_object

-- my own custom textobjects
local textobjs = require("config.textobjs")
-- create custom operators easily
local operators = require("config.operators")

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
            utils.error("Map/" .. cmd, err:gsub("^Vim:E%d+:%s*", ""))
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
        utils.error("Map/" .. cmd, err:gsub("^Vim:E%d+:%s*", ""))
    end
end
-- }}}

-- Unmap Unused {{{
map("n", "gQ", "<nop>") -- ex mode is just plain annoying

-- ZZ and ZQ are not that short and often just annoying
map("n", "Z", "<nop>")

-- i don't like the lsp mappings
unmap("n", "grn") -- rename
unmap("n", "gra") -- actions
unmap("n", "grr") -- references
unmap("n", "gri") -- implementation
-- }}}

--[[ qflist / loclist {{{
Navigate faster with the lists
The qflist is generally used for workspace wide things
The loclist per each buffer/window
]]

-- qflist: more mappings, larger lists
map("n", "<C-j>", cmd_with_count("cnext"))
map("n", "<C-k>", cmd_with_count("cprev"))
map("n", "<space>0", "<cmd>cfirst<cr>")
map("n", "<space>$", "<cmd>clast<cr>")

-- loclist: optimized for much smaller lists
map("n", "<M-j>", cmd_with_count("lnext"))
map("n", "<M-k>", cmd_with_count("lprev"))

-- clear them
map("n", "<space>qc", function()
    fn.setqflist({}, "r")
    require("quicker").close()
end, { desc = "Qflist: Clear" })
map("n", "<space>lc", function()
    fn.setloclist(0, {}, "r")
    require("quicker").close { loclist = true }
end, { desc = "Loclist: Clear" })

-- move through the histories
map("n", "<space>qn", cmd_with_count("cnewer"), { desc = "Qflist: Newer" })
map("n", "<space>qo", cmd_with_count("colder"), { desc = "Qflist: Older" })
map("n", "<space>ln", cmd_with_count("lnewer"), { desc = "Loclist: Newer" })
map("n", "<space>lo", cmd_with_count("lolder"), { desc = "Loclist: Older" })

-- error numbers
map("n", "<space>Q", cmd_with_count("cc"))
map("n", "<space>L", cmd_with_count("ll"))

-- vertical view
map("n", "<space>qv", function()
    local qfwin = fn.getqflist { winid = true }.winid
    if qfwin == 0 then
        require("quicker").open()
        qfwin = fn.getqflist { winid = true }.winid
    end

    api.nvim_win_set_config(qfwin, {
        split = "left",
        width = 72,
        vertical = true
    })
    vim.wo[qfwin][0].number = true
end, { desc = "Qflist: Vertical" })

map("n", "<space>lv", function()
    local locwin = fn.getloclist(0, { winid = true }).winid
    if locwin == 0 then
        require("quicker").open { loclist = true }
        locwin = fn.getloclist(0, { winid = true }).winid
    end

    api.nvim_win_set_config(locwin, {
        split = "left",
        width = 72,
        vertical = true
    })
    vim.wo[locwin][0].number = true
end, { desc = "Loclist: Vertical" })

-- Reuse [g]o [l]ist prefix, Uppercase for qflist
-- set lists to diagnostics
map("n", "glE", function() vim.diagnostic.setqflist { open = true } end, { desc = "Qflist: Diagnostics ([E]rrors)" })
map("n", "gle", function() vim.diagnostic.setloclist { open = true } end, { desc = "Loclist: Diagnostics ([E]rrors)" })
-- list all TODOs, only when followed by a description
map("n", "glT", "<cmd>silent grep '\\bTODO:'|cwin<cr>", { desc = "Qflist: TODOs" })
map("n", "glt", "<cmd>silent lvimgrep /\\<TODO:/ %|lwin<cr>", { desc = "Loclist: TODOs" })

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

map("n", "gls", function()
    fn.setloclist(0, get_spelling_errors())
end, { desc = "Loclist: Spelling" })

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

map("n", "<space>qr", function() require("quicker").refresh(nil, { keep_diagnostics = true }) end)
map("n", "<space>lr", function() require("quicker").refresh(0, { keep_diagnostics = true }) end)

-- toggle them
map("n", "'q", function() require("quicker").toggle { min_height = 8 } end)
map("n", "'l", function() require("quicker").toggle { min_height = 8, loclist = true } end)
-- }}}

-- Navigation {{{

--[[ focus the current fold
- zM: close all folds
- zO: open the current one, recursively
- [z: move to the top of it
- zt: place it at the top of the screen
the j is required so that this applies when on the fold start ]]
map("n", "<Tab>", "zMzOj[zzt", { remap = true --[[ is required so ufo applies ]] })
-- }}}

-- Buffers & Windows {{{
local bufleader = "'"

-- there still is ` for marks, ' is on the home row, soooo nice
map("n", bufleader, "<nop>")

-- faster alternate file, mnemonic: [s]econd, also allows remapping <C-6>
map("n", "<C-s>", "<cmd>b #<cr>")
map("n", bufleader .. "j", "<cmd>bnext<cr>", { desc = "Buffer: Next" })
map("n", bufleader .. "k", "<cmd>bprev<cr>", { desc = "Buffer: Prev" })

local function get_buf_idx()
    local target
    local count = vim.v.count
    if count == 0 then
        target = api.nvim_get_current_buf()
    else
        target = Bufs_for_idx[count]
    end
    if not target or not api.nvim_buf_is_valid(target) then
        utils.error("Mappings", "No Buffer " .. count)
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

map("n", bufleader .. '"', function() indexed_tab_command("norm! gt") end, { desc = "Tab: Show" })
map("n", bufleader .. "D", function() indexed_tab_command("tabclose") end, { desc = "Tab: Delete" })
-- }}}

-- Improve Builtin Mappings {{{
-- stop {} from polluting the jumplist

-- make them wait until I press another key
-- most useful for leaders like this
map("n", "\\", "<nop>")
map("n", "<space>", "<nop>")

map(mov, "{", function() return "<cmd>keepj normal!" .. vim.v.count1 .. "{<cr>" end, { remap = false, expr = true })
map(mov, "}", function() return "<cmd>keepj normal!" .. vim.v.count1 .. "}<cr>" end, { remap = false, expr = true })

-- center the screen for jumps
map(mov, "<C-o>", "<C-o>zz")
map(mov, "<C-i>", "<C-i>zz")

--[[ those are hard to reach by default,
I do not use Low and High for navigation and even rarer in o-pending mode
also kinda logical, a stronger version of lh ]]
map(mov, "L", "$")
map(mov, "H", "^")

-- keep the old ones around though
map(mov, "gL", "L")
map(mov, "gH", "H")

-- % is annoying to press, [m]atching, this takes some inspiration from helix
map(obj, "m", "<plug>(matchup-%)")
map(obj, "im", "<plug>(matchup-i%)")
map(obj, "am", "<plug>(matchup-a%)")

-- more humane spell popup
map("n", "z=", function()
    local word = fn.expand("<cWORD>")
    local suggestions = fn.spellsuggest(word, 32)
    vim.ui.select(suggestions, { prompt = "Spell" }, function(replacement)
        if not replacement then
            return
        end

        vim.cmd([[normal! "_diW]])
        api.nvim_paste(replacement, false, -1)
    end)
end)

-- allow modifying count in o-pending mode
local modify_operator_count = function(delta)
    local keys = ("\x1b%s%d"):format(vim.v.operator, math.max(1, vim.v.count + delta))
    api.nvim_feedkeys(keys, "")
end

map("o", "<C-a>", function()
    modify_operator_count(1)
end)
map("o", "<C-x>", function()
    modify_operator_count(-1)
end)

map("o", "*", function()
    return "\x1b*N" .. vim.v.operator .. "gn"
end, { expr = true })

-- like (now-default) []<space>, but for characters inside a line, e.g. to separate words
local insert_spaces = function(direction)
    local spaces = (" "):rep(vim.v.count1)
    local cursor = api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = direction < 0 and cursor[2] or cursor[2] + 1
    api.nvim_buf_set_text(0, row, col, row, col, { spaces })
end

map("n", "<<space>", function()
    insert_spaces(-1)
end)
map("n", "><space>", function()
    insert_spaces(1)
end)

-- show marks before jumping
map("n", "`", function()
    local marks = vim.tbl_map(function(m)
        return {
            m.mark:sub(2),
            m.pos[2],
            { api.nvim_buf_get_lines(m.pos[1], m.pos[2] - 1, m.pos[2], false)[1] or "" }
        }
    end, fn.getmarklist(""))

    vim.list_extend(marks, vim.tbl_map(function(m)
        local name, parent, hl = utils.format_filepath(m.file, 4)
        return {
            m.mark:sub(2),
            m.pos[2],
            { parent, "NonText" },
            { name,   hl }
        }
    end, fn.getmarklist()))

    local buf = api.nvim_create_buf(false, true)
    local win = api.nvim_open_win(buf, false, {
        style = "minimal",
        anchor = "SW",
        relative = "laststatus",
        height = #marks + 1,
        width = 60,
        row = 0,
        col = 0,
    })

    api.nvim_buf_set_extmark(buf, hlns, 0, 0, {
        virt_lines_above = true,
        virt_lines = vim.tbl_map(function(m)
            return {
                { m[1],                 "Identifier" },
                { "    " },
                { ("%3d"):format(m[2]), "Number" },
                { " " },
                m[3],
                m[4]
            }
        end, marks)
    })
    api.nvim_buf_set_lines(buf, 0, 0, false, { "" })
    api.nvim_buf_set_extmark(buf, hlns, 1, -1, {
        virt_text_pos = "inline",
        virt_text = {
            { "Mark Row Content/File", "Title" },
        }
    })


    vim.cmd.redraw()
    local reg = fn.getcharstr(-1, { cursor = "hide" })

    api.nvim_win_close(win, true)

    local ok, err = pcall(api.nvim_cmd, {
        cmd = "normal",
        bang = true,
        args = { "'" .. reg },
    }, {})

    if not ok then
        utils.error("Marks", err, true)
    end
end)

---@param c string
local is_ascii_lower = function(c)
    local code = c:byte()
    return c <= "\x7a" and c >= '\x61'
end

-- Set next mark that matches the line text
map("n", "m,", function()
    local line = api.nvim_get_current_line()
    for i = 1, #line do
        local m = line:sub(i, i):lower()
        if is_ascii_lower(m) and api.nvim_buf_get_mark(0, m)[1] == 0 then
            vim.cmd.mark(m)
            utils.message("Marks", "Set " .. m)
            return
        end
    end
end)
-- }}}

-- Set options {{{
-- [c]onfigure
map("n", "<space>cs", "<cmd>Spell toggle<cr>", { desc = "Toggle 'spell'" })
map("n", "<space>cg", "<cmd>Spell set de<cr>", { desc = "German spelling" })
map("n", "<space>ce", "<cmd>Spell set en<cr>", { desc = "English spelling" })
map("n", "<space>cl", "<cmd>set list!<cr>", { desc = "Toggle 'list'" })
map("n", "<space>cw", "<cmd>set wrap!<cr>", { desc = "Toggle 'wrap'" })

map("n", "<space>cW", function()
    vim.o.textwidth = vim.v.count * 10
end)
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
    vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
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
-- }}}

-- Give Q more purpose {{{
-- use <C-q> for macros instead, i don't use them that often
-- use "reg, like other vim commands, defaulting to "q
map("n", "<C-q>", function()
    if fn.reg_recording() ~= "" then
        return "q"
    else
        local reg = vim.v.register
        return "q" .. (reg ~= '"' and reg or "q")
    end
end, { expr = true })

-- faster to close windows and cycle
map("n", "q", function()
    local ok = pcall(vim.cmd.close)
    if not ok then
        vim.cmd.bnext()
    end
end)
-- }}}

-- Abbrevs {{{
-- force quit
abbrev("c", "Q", "q!")
abbrev("c", "Qa", "qa!")

-- I probably never will actually use :file
-- If I need it, i can survive typing the full name
abbrev("c", "f", "find")
abbrev("c", "vf", "vertical sf") -- much shorter, much more useful

-- often useful for one-off commands
abbrev("c", "vt", "vertical terminal")
abbrev("c", "st", "horizontal terminal")

-- same for fugitive
abbrev("c", "vG", "vertical Git")
abbrev("c", "sG", "horizontal Git")

abbrev("c", "v!", "vertical")   -- :v doesn't take !bang anyways
abbrev("c", "s!", "horizontal") -- same for consistency
-- }}}

-- Terminal {{{
local terminal = require("config.terminal")

local termleader = "<space>t"
map("n", termleader .. "s", function() terminal.open_term { position = "horizontal" } end)
map("n", termleader .. "v", function() terminal.open_term { position = "vertical" } end)
map("n", termleader .. "x", function() terminal.open_term { position = "replace" } end)
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
map("t", "<C-w>", "<C-\\><C-n><C-w>")

map("n", termleader .. "p", function()
    local termbuf = vim.b[0].terminal_buffer or terminal.last_term
    if not termbuf then
        return
    end
    local outputs = terminal.command_output_for_buffers[termbuf]
    local selected = #outputs - vim.v.count
    local region = outputs[selected]
    if region then
        api.nvim_paste(
            table.concat(api.nvim_buf_get_lines(termbuf, region[1], region[2] - 1, false), "\n"),
            false, -1
        )
    end
end, { desc = "Terminal: Paste command output" })
-- }}}

-- Insert Mode {{{
--[[ Why would I want to do smth so un-vimmy?
Well, on my keyboard tapping L/R Shift yields BS/Del,
so tapping one shift key while holding the other makes sense ]]
map("i", "<S-BS>", "<C-w>")
map("i", "<S-Del>", "<c-o>\"_dw")

-- fix spelling error ahead
map("i", "<C-s>", "<esc>[sz=", { remap = true })

-- move between arguments, that's one of the only things i actually do in insert mode
-- [f]orward, [b]ackward
map("i", "<C-f>", "<C-o>]a", { remap = true })
map("i", "<C-b>", "<C-o>[a", { remap = true })
-- }}}

-- Snippets {{{
-- move between snippet fields
map({ "n", "s", "i" }, "<M-space>", function() vim.snippet.jump(1) end)
map({ "n", "s", "i" }, "<C-space>", function() vim.snippet.jump(-1) end)
-- }}}

-- Diagnostics {{{
map("n", "<space>d", vim.diagnostic.open_float)

-- target the area of a diagnostic with a textobject
-- <id> matches every type
map(obj, "id", textobjs.diagnostic)
map(obj, "iDe", textobjs.diagnostic_error)
map(obj, "iDw", textobjs.diagnostic_warn)
map(obj, "iDi", textobjs.diagnostic_info)
map(obj, "iDh", textobjs.diagnostic_hint)
-- }}}

-- Additional Textobjects {{{
-- less annoying to type
map(obj, "iq", [[i"]])
map(obj, "aq", [[a"]])
map(obj, "iQ", [[i']])
map(obj, "aQ", [[a']])

--[[ indents, very useful for python or other indent based languages
 a includes one line above and below,
 except for filetypes like python or lisps where only the above line is included by default
 aI always includes the line below too, even for python et cetera,
 useful for object literals like dicts or lists

 if present, v:count specifies the amount of indent levels instead of the current cursor position
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

-- operand to arithmetic
map(obj, "io", textobjs.create_pattern_obj("([-+*/%%]%s*)[%w_%.]+()"))
map(obj, "ao", textobjs.create_pattern_obj("()[-+*/%%]%s*[%w_%.]+()"))

-- snake_case or kebab-case word
map(obj, "i-", textobjs.create_pattern_obj("([-_]?)%w+([-_]?)"))
map(obj, "a-", textobjs.create_pattern_obj("()[-_]?%w+[-_]?()"))

-- object chain, most languages, NOTE: does not include lua `:`
map(obj, "i.", textobjs.create_pattern_obj("()[%w._]+()"))
map(obj, "a.", textobjs.create_pattern_obj("()%s*[%w._]+%s*()"))

-- path component, NOTE: around does only includes final slashes
map(obj, "i/", textobjs.create_pattern_obj("()[^/]+()"))
map(obj, "a/", textobjs.create_pattern_obj("()[^/]+()/*"))

-- entire buffer, mirroring the motions that would achieve the same thing: VgG
map(obj, "gG", textobjs.entire_buffer)

-- a C-style variable value; ignore visual mode since = is useful there
map("o", "=", textobjs.variable_value)
-- }}}

-- Sort Region {{{
local sort_functions = {
    numeric = function(x, y)
        local xnumeric = x:match("^[+-]?%d*%.?%d+")
        local ynumeric = y:match("^[+-]?%d*%.?%d+")
        -- sort alphabetic
        local xnum = xnumeric and tonumber(xnumeric) or nil
        local ynum = ynumeric and tonumber(ynumeric) or nil
        if (not xnum) and (not ynum) then
            -- fall back to alphabetic comparisons
            return x < y
        end

        -- sort pure text at the end of the list
        return (xnum or math.huge) < (ynum or math.huge)
    end,
    string = function(x, y)
        return x < y
    end
}

-- charwise: csv
-- linewise: lines
-- preserves indent/spacing
---@diagnostic disable-next-line: unused-local
operators.map_function("g=", function(mode, region, extra, get, set)
    local split
    if mode == "char" then
        local content = table.concat(get(), "")
        split = vim.split(content, ",")
    else
        split = get()
    end

    local no_whiteonly = vim.tbl_filter(function(v)
        return not v:match("^%s*$")
    end, split)

    local to_sort = {}
    local init_white = {}
    local post_white = {}
    for i, val in ipairs(no_whiteonly) do
        init_white[i], to_sort[i], post_white[i] = val:match("^(%s*)(.-)(%s*)$")
    end

    local sort_fun
    if to_sort[1]:match("^[+-]?%d*%.?%d+") then
        sort_fun = sort_functions.numeric
    else
        sort_fun = sort_functions.string
    end

    table.sort(to_sort, sort_fun)
    local sorted = {}
    for i, val in ipairs(to_sort) do
        table.insert(sorted, init_white[i] .. val .. post_white[i])
    end

    local output
    if mode == "char" then
        output = { table.concat(sorted, ",") }
    else
        output = sorted
    end

    set(region, output)
end)
-- }}}

-- Command in Region {{{
-- open a cmdline in a region specified by a textobject or motion
-- allows me to repeat commands like they're regular mappings
---@diagnostic disable-next-line: unused-local
operators.map_function("g:", function(mode, region, extra, get, set)
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
-- }}}

--[[ Change Directory {{{
Sometimes I need a quicker way to change directory than :cd, :lcd etc
This may benefit from being turned into a sub mode sometime
]]
local cdleader = "<space>."

local function get_cur_buf_parent()
    local path = fn.expand("%:h"):gsub("^oil://", "")
    return path
end

-- goto parent
map("n", cdleader .. "h", function()
    local dir = fn.getcwd(0, 0)
    vim.cmd.lcd(fn.fnamemodify(dir, ":h"))
end)

-- go one element right in current files path
map("n", cdleader .. "l", function()
    local dir = fn.getcwd(0, 0)
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
end)

-- go to current files dir
map("n", cdleader .. "c", function()
    vim.cmd.lcd(get_cur_buf_parent())
end)

-- go to project root
map("n", cdleader .. "r", function()
    local root
    local clients = vim.lsp.get_clients { bufnr = api.nvim_get_current_buf() }
    if #clients > 0 then
        root = clients[1].root_dir
    end

    if not root then
        root = vim.fs.root(fn.getcwd(0, 0), { ".git", "Makefile" })
    end

    if root then
        vim.cmd.lcd(root)
    end
end)
-- }}}

-- Table of Content {{{
-- like the one in a help buffer
-- based on folds, so it works for most filetypes
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
        or at_first_level > 20 and 0 or 1 -- show more detail in shorter files
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

-- view information in manpage or help
-- this is also meant to be overridden if necessary, which is why it's here
map({ "v", "n" }, "gK", function()
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
