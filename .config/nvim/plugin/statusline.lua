local api = vim.api
local fn = vim.fn
local utils = require("config.utils")

-- my own statusline
-- this should be faster than lualine
-- generally, only redraw things using autocmds unless there isn't a good one for the event
-- also, schedule autocommand based redraws

-- Utility functions {{{
local function esc(str)
    return str:gsub("%%", "%%%%")
end

local delim = " %#SlDelim#| %*"
-- }}}

-- Mode Element {{{
-- Change color with mode
local mode_to_hl_group = {
    n        = "Normal",
    i        = "Insert",
    c        = "Command",
    v        = "Visual",
    V        = "Visual",
    ["\x16"] = "Visual",
    ["\x13"] = "Visual",
    ["S"]    = "Visual",
    s        = "Visual",
    t        = "Insert",
    R        = "Replace",
    r        = "Command",
    ["!"]    = "Command",
}

local mode_to_name = {
    ["n"]      = "N",
    ["no"]     = "o",
    ["nov"]    = "_o",
    ["noV"]    = "O",
    ["no\x16"] = "^O",
    ["c"]      = "C",

    ["v"]      = "v",
    ["V"]      = "V",
    ["\x16"]   = "^V",
    ["\x13"]   = "^S",
}

local function update_mode()
    local mc = require("multicursor-nvim")
    local has_multicursor = mc.hasCursors()

    local mode = api.nvim_get_mode().mode
    local short = mode:sub(1, 1)
    local hl = mode_to_hl_group[short]

    return string.format("%%#SlMode%s#%-3s",
        hl,
        (has_multicursor and mc.numCursors() or "") .. (mode_to_name[mode] or short)
    )
end
-- }}}

-- Current Macro {{{
local function update_macro(ev)
    if ev == "RecordingLeave" then
        local last = vim.fn.reg_recording()
        if last == "" then
            return ""
        end

        return ("%%#SlMacro#@%s "):format(last)
    else
        local reg = vim.fn.reg_recording()
        return ('%%#SlMacro#>%s '):format(reg)
    end
end
-- }}}

-- Current Buffer Title {{{
local function update_title()
    local buf = api.nvim_get_current_buf()
    local name, kind, show_modified = utils.format_buf_name(buf)

    local changed = vim.bo[buf].modified
    local readonly = vim.bo[buf].readonly or not vim.bo[buf].modifiable

    return string.format("%%#SlI%s#(%s) %%#SlIText#%s%s%s",
        utils.btypehighlights[kind],
        utils.btypenames[kind],
        name and esc(name) or "[-]",
        (readonly and show_modified) and "%#SlIReadonly# [ro]" or "",
        (show_modified
            and (changed and "%#SlIChanged#~" or (" "))
            or "")
    )
end
-- }}}

-- Git {{{
-- extra info for fugitive buffers
local function get_fugitive_info()
    local res = {}

    local head = fn.FugitiveHead(8)
    if head and head ~= "" then
        table.insert(res, string.format("%s", head))
    end

    ---@type string
    local object = fn["fugitive#Object"](api.nvim_buf_get_name(0))
    if object then
        if vim.startswith(object, "/tmp") then
            object = "log"
        elseif object:match("^%x+$") then
            object = object:sub(0, 8)
        elseif object:match("^%x+:.*$") then
            object = "#" .. object:sub(0, 8)
        elseif object == ":" then
            object = "status"
        else
            local ago = object:match("^:(%d+):.*")
            if ago == "0" then
                object = "HEAD"
            end
        end
        table.insert(res, string.format("%%#Identifier#%s", object))
    end

    return delim .. table.concat(res, " ")
end

local function update_git()
    if vim.b[0].fugitive_type then
        return get_fugitive_info()
    end

    if not vim.b[0].gitsigns_status_dict then
        return ""
    end
    local status = vim.b[0].gitsigns_status_dict

    local res = {}
    if status.head then
        table.insert(res, string.format("%s", status.head))
    end
    if status.added and status.added > 0 then
        table.insert(res, string.format("%%#Added#+%d", status.added))
    end
    if status.changed and status.changed > 0 then
        table.insert(res, string.format("%%#Changed#~%d", status.changed))
    end
    if status.removed and status.removed > 0 then
        table.insert(res, string.format("%%#Removed#-%d", status.removed))
    end

    if #res == 0 then
        return ""
    end

    return delim .. table.concat(res, " ")
end
-- }}}

-- Diagnostics {{{
local function update_diagnostics()
    local sev = vim.diagnostic.severity
    local count = vim.diagnostic.count(0)
    if vim.tbl_count(count) == 0 then
        return ""
    end

    local err = count[sev.ERROR] or 0
    local warn = count[sev.WARN] or 0
    local hint = count[sev.HINT] or 0
    local info = count[sev.INFO] or 0

    local res = {}
    if err > 0 then
        table.insert(res, string.format("%%#DiagnosticError#!%d", err))
    end
    if warn > 0 then
        table.insert(res, string.format("%%#DiagnosticWarn#!%d", warn))
    end
    if hint > 0 then
        table.insert(res, string.format("%%#DiagnosticHint#?%d", hint))
    end
    if info > 0 then
        table.insert(res, string.format("%%#DiagnosticInfo#.%d", info))
    end

    return delim .. table.concat(res, " ")
end
-- }}}

-- Searchcount {{{
local update_searchcount = function()
    if vim.v.hlsearch == 0 then
        return nil
    end

    local ok, res = pcall(fn.searchcount, { maxcount = 999, timeout = 500 })
    if not ok or next(res) == nil then
        return nil
    end

    if res.total == 0 then
        return delim .. "no matches"
    end

    return ("%s%s%s%%* of %s%d"):format(delim,
        res.exact_match == 1 and "%#SlOnSearch#" or "",
        res.current > 999 and "?" or res.current,
        res.incomplete == 2 and ">" or "",
        res.total
    )
end
-- }}}

-- Word, Char, Byte and Line -count {{{
local function update_words()
    local count = fn.wordcount()
    local linecount = api.nvim_get_mode().mode:find("^[vV\x16]$")
        and math.abs(fn.getpos("v")[2] - api.nvim_win_get_cursor(0)[1]) + 1
        or api.nvim_buf_line_count(0)

    local words = count.visual_words or count.words
    local chars = count.visual_chars or count.chars
    local bytes = count.visual_bytes or count.bytes
    local out = {}

    table.insert(out, string.format("%s%%#SlWords#W%%* %s%%#SlChars#C%%* %s%%#SlLines#L%%* %s%%#SlBytes#B",
        utils.format_size(words),
        utils.format_size(chars),
        utils.format_size(linecount),
        utils.format_size(bytes, 1024)
    ))

    return table.concat(out, " ")
end
-- }}}

-- Buffer and window local options {{{
local function update_filetype()
    local bo = vim.bo
    local wo = vim.wo

    local _ft = bo.filetype
    local ft = _ft and _ft ~= "" and _ft or "[noft]"

    local spell = wo.spell and ("spl:%s "):format(bo.spelllang) or ""

    local _enc = bo.fileencoding
    local enc = _enc and _enc ~= "" and _enc or "utf-8"

    local _tw = bo.textwidth
    local tw = _tw == 0 and "" or ("tw:%d "):format(_tw)

    local indent = bo.expandtab
        and ("sw:%d"):format(bo.shiftwidth)
        or "tab"

    local concealcursor = wo.concealcursor
    if #concealcursor == 4 then
        concealcursor = "*"
    elseif concealcursor == "" then
        concealcursor = "_"
    end

    local conceallevel = wo.conceallevel
    local conceal = conceallevel > 0 and ("cc:%s "):format(concealcursor) or ""

    return delim .. string.format("%%*%s %s %s %s%s%s%s",
        enc,
        bo.fileformat,
        indent,
        tw,
        conceal,
        spell,
        ft
    )
end
-- }}}

-- Attached LSPs {{{
local function update_lsp_servers()
    local clients = vim.lsp.get_clients { bufnr = 0 }

    return #clients > 0
        and (" (%s)"):format(table.concat(vim.tbl_map(function(c)
            return c.name
        end, clients), " "))
        or ""
end
-- }}}

local sections
local indices = {
    mode        = 2,
    macro       = 4,
    title       = 5,
    git         = 6,
    diagnostics = 7,
    search      = 8,

    words       = 11,
    filetype    = 12,
    lsp         = 13,
}

local last_update = 0
local redraw = function()
    local now = vim.uv.now()
    if now - last_update > 100 then
        vim.o.statusline = table.concat(sections)
    end
end

-- Autocommands {{{
local current_buf = nil
local group = api.nvim_create_augroup("config.statusline", { clear = true })

---@param event string|string[]
---@param tbl vim.api.keyset.create_autocmd
local redraw_on = function(event, tbl, always)
    local fun = tbl.callback
    tbl.group = group
    tbl.callback = function(ev)
        if not always and ev.buf ~= current_buf then
            return
        end
        fun --[[@as function]](ev)
    end
    api.nvim_create_autocmd(event, tbl)
end

api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
        current_buf = ev.buf
    end
})

redraw_on("ModeChanged", {
    callback = function(ev)
        -- stop flickering
        if vim.bo[ev.buf].filetype == "TelescopePrompt" then
            return
        end
        sections[indices.mode] = update_mode()
        redraw()
    end
})
redraw_on("ModeChanged", {
    pattern = "v:*,V:*,\x16:*",
    callback = function()
        sections[indices.words] = update_words()
        redraw()
    end
})
redraw_on({ "BufEnter", "BufLeave", "CmdlineLeave" }, {
    callback = vim.schedule_wrap(function()
        sections[indices.title] = update_title()
        sections[indices.git] = update_git()
        sections[indices.lsp] = update_lsp_servers()
        sections[indices.diagnostics] = update_diagnostics()
        sections[indices.filetype] = update_filetype()
        sections[indices.words] = update_words()
        redraw()
    end)
})
redraw_on({ "BufModifiedSet", "FileChangedRO", "TermRequest" }, {
    callback = function()
        sections[indices.title] = update_title()
        redraw()
    end
})
redraw_on({ "TextChanged", "TextChangedI" }, {
    callback = function()
        sections[indices.words] = update_words()
        redraw()
    end
})

redraw_on("OptionSet", {
    pattern = { "spell", "spellang", "shiftwidth", "expandtab", "conceallevel", "concealcursor", "filetype", "textwidth" },
    callback = vim.schedule_wrap(function()
        local mode = api.nvim_get_mode().mode:sub(1, 1)
        if not (mode == "n" or mode == "c") then
            return
        end
        sections[indices.filetype] = update_filetype()
        redraw()
    end)
}, true)
redraw_on({ "RecordingEnter", "RecordingLeave" }, {
    callback = function(ev)
        sections[indices.macro] = update_macro(ev.event)
        redraw()
    end
})
redraw_on({ "LspAttach", "LspDetach" }, {
    callback = vim.schedule_wrap(function()
        sections[indices.lsp] = update_lsp_servers()
        redraw()
    end)
})
redraw_on("User", {
    pattern = { "FugitiveChanged", "FugitiveObject", "GitSignsUpdate" },
    callback = vim.schedule_wrap(function()
        sections[indices.git] = update_git()
        redraw()
    end)
})

redraw_on("DiagnosticChanged", {
    callback = function()
        sections[indices.diagnostics] = update_diagnostics()
        redraw()
    end
})
-- }}}

local update_timer = assert(vim.uv.new_timer())
local last_hlsearch
update_timer:start(0, 200, vim.schedule_wrap(function()
    local mode = api.nvim_get_mode().mode:sub(1, 1)
    local should_redraw = false
    if mode == "v" or mode == "V" or mode == "\x16" then
        -- the selection might have changed
        sections[indices.words] = update_words()
        should_redraw = true
    end

    local new = update_searchcount()
    if new or last_hlsearch then
        sections[indices.search] = new or ""
        -- redraw if the state changed or hlsearch is active
        should_redraw = true
    end
    last_hlsearch = new

    if should_redraw then
        redraw()
    end
end))

local bracket_left = "%#SlISL#"
local bracket_right = "%#SlISR#"

-- prefill the line
-- some will be static, some only updated via autocmd, some via timer
sections = {
    bracket_left,
    update_mode(),            -- mode
    "%#SlTyped#%-5(%S%)",     -- current keys
    "",                       -- macro register
    "",                       -- title of buffer with modified etc
    "",                       -- git
    "",                       -- diagnostics
    "",                       -- searchcount
    delim .. "%*%P %3l,%-3c", -- cursor position

    -- separate the two parts, a bracket on each side
    bracket_right
    .. "%#Normal#%=%<"
    .. bracket_left
    .. "%*",

    "", -- counts
    "", -- filetype
    "", -- attached LSPs
    bracket_right,
}

vim.o.laststatus = 3
vim.o.showcmdloc = "statusline"
