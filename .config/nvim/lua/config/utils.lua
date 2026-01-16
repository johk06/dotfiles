local M = {}
local api = vim.api
local fn = vim.fn
local bit = require("bit")
local string_buffer = require("string.buffer")
-- Reusable code for my entire config

-- format buffer title {{{
-- names for special filetypes {{{1
local nomodified_names = {
    undotree = { "[undo]" },
    fugitive = { "[git]", "git" },
    checkhealth = { "[health]" },
    lazy = { "[lazy]" },
    mason = { "[mason]" },
    orgagenda = { "[org: Agenda]" },
    ["grug-far"] = { "[grug-far]" }
}

local modified_names = {
    gitcommit = { "[commit]", "git" },
    grapple = { "[grapple]" },
}
-- }}}

local function expand_home(path, length)
    local user = vim.env.USER
    local home = "/home/" .. user
    return fn.pathshorten(path:gsub("/tmp/workspaces_" .. user, "~tmp")
        :gsub(home .. "/ws", "~ws")
        :gsub(home .. "/.config", "~cfg")
        :gsub(home, "~"), length or 6)
end

M.expand_home = expand_home

local buf_list_type = {}
---@param buf integer
---@param short boolean?
---@return string? name
---@return string kind
---@return boolean should_show_modified
function M.format_buf_name(buf, short)
    local bvar = vim.b[buf]

    local term_title = bvar.term_title
    if term_title then
        local program, path = term_title:match("(.-): (.*)")
        if not (program and path) then
            return term_title, "term", false
        end

        return ("%s: %s"):format(program, expand_home(path, 4)), "term", false
    end

    local name = api.nvim_buf_get_name(buf)
    local ft = vim.bo[buf].filetype

    if ft == "oil" then
        local ret
        if vim.startswith(name, "oil-ssh://") then
            local _, _, host, path = name:find("//([^/]+)/(.*)")
            ret = "@" .. host .. ":" .. path
        else
            ret = expand_home(name:sub(#"oil://" + 1, -2), 3) .. "/"
        end
        return ret, "oil", true
    elseif ft == "help" then
        return ":h " .. fn.fnamemodify(name, ":t"):gsub("%.txt$", ""), "help", false
    elseif ft == "git" then
        return "[git]", "git", false
    elseif ft == "fugitiveblame" then
        return "[git-blame]", "git", false
    elseif ft == "man" then
        return "man " .. fn.fnamemodify(name, ":t"), "help", false
    elseif ft == "qf" then
        if not buf_list_type[buf] then
            local win = fn.bufwinid(buf)
            local isloclist = fn.getwininfo(win)[1].loclist == 1
            buf_list_type[buf] = isloclist and "[loc]" or "[qf]"
        end
        return buf_list_type[buf], "list", false
    elseif ft == "TelescopePrompt" then
        local picker = require("telescope.actions.state").get_current_picker(buf)
        return ("[tel: %s]"):format(picker.prompt_title), "special", false
    elseif nomodified_names[ft] then
        return nomodified_names[ft][1], nomodified_names[ft][2] or "special", false
    elseif modified_names[ft] then
        return modified_names[ft][1], modified_names[ft][2] or "special", true
    elseif vim.startswith(name, "fugitive://") then
        return expand_home(fn.fnamemodify(name:gsub("fugitive://.-.git//%d+/", ""), ":t")), "git", true
    end

    local normal_buf = vim.bo[buf].buftype == ""
    if name and name ~= "" then
        if bvar.special_bufname then
            return bvar.special_bufname, "special", true
        elseif normal_buf then
                local ret = expand_home(name)
                if short then
                    ret = fn.fnamemodify(ret, ":t")
                end
                return ret, "reg", true
        else
            if vim.startswith(name, "oil-ssh://") then
                local _, _, host, path = name:find("//([^/]+)/(.*)")
                return "@" .. host .. ":" .. fn.fnamemodify(path, ":t"), "reg", true
            else
                -- try to get smth reasonable for plugin provided buffers
                return fn.fnamemodify(name, ":t"), "special", true
            end
        end
    end

    return nil, "empty", true
end

M.btypehighlights = {
    empty = "Reg",
    git = "Git",
    help = "Help",
    list = "List",
    oil = "Dir",
    reg = "Reg",
    special = "Special",
    term = "Term",
}

M.btypesymbols = {
    empty = "#",
    git = "@",
    help = "?",
    list = "$",
    oil = ":",
    reg = "#",
    special = "*",
    term = "!",
}

M.btypenames = {
    empty = "Empty",
    git = "Git",
    help = "Help",
    list = "List",
    oil = "Dir",
    reg = "File",
    special = "Special",
    term = "Term",
}

-- }}}

-- highlight file path {{{
-- patterns {{{1
local extension_highlights = {
    ["S"]       = "Code",
    ["a"]       = "Archive",
    ["as"]      = "Code",
    ["c"]       = "Code",
    ["cc"]      = "Code",
    ["cfg"]     = "Config",
    ["conf"]    = "Config",
    ["cpp"]     = "Code",
    ["css"]     = "Style",
    ["desktop"] = "Config",
    ["go"]      = "Code",
    ["gz"]      = "Archive",
    ["h"]       = "Header",
    ["hh"]      = "Header",
    ["hpp"]     = "Header",
    ["hs"]      = "Code",
    ["html"]    = "Text",
    ["ini"]     = "Config",
    ["jar"]     = "Archive",
    ["jpg"]     = "Ignore",
    ["js"]      = "Code",
    ["json"]    = "Config",
    ["jsonc"]   = "Config",
    ["log"]     = "Info",
    ["lua"]     = "Code",
    ["md"]      = "Text",
    ["mk"]      = "Build",
    ["nu"]      = "Code",
    ["o"]       = "Ignore",
    ["odt"]     = "Ignore",
    ["pdf"]     = "Ignore",
    ["png"]     = "Ignore",
    ["py"]      = "Code",
    ["pyc"]     = "Ignore",
    ["rc"]      = "Config",
    ["rs"]      = "Code",
    ["sass"]    = "Style",
    ["scm"]     = "Code",
    ["scss"]    = "Style",
    ["sh"]      = "Code",
    ["so"]      = "Ignore",
    ["svg"]     = "Style",
    ["tar"]     = "Archive",
    ["tex"]     = "Cod",
    ["toml"]    = "Config",
    ["ts"]      = "Code",
    ["txt"]     = "Text",
    ["typ"]     = "Code",
    ["vim"]     = "Code",
    ["xhtml"]   = "Config",
    ["xml"]     = "Config",
    ["xz"]      = "Archive",
    ["yaml"]    = "Config",
    ["yuck"]    = "Code",
    ["zig"]     = "Code",
    ["zip"]     = "Archive",
    ["zsh"]     = "Code",
}

-- case insensitive
local name_highlights = {
    [".clang-format"]         = "Meta",
    [".clangd"]               = "Meta",
    [".config/"]              = "Config",
    [".editorconfig"]         = "Meta",
    [".git/"]                 = "Ignore",
    [".gitconfig"]            = "Git",
    [".gitignore"]            = "Git",
    ["changelog.md"]          = "Readme",
    ["commit_editmsg"]        = "Git",
    ["compile_commands.json"] = "Ignore",
    ["config"]                = "Config",
    ["copying"]               = "Readme",
    ["credits"]               = "Readme",
    ["go.mod"]                = "Build",
    ["license"]               = "Readme",
    ["license.md"]            = "Readme",
    ["license.txt"]           = "Readme",
    ["maintainers"]           = "Readme",
    ["makefile"]              = "Build",
    ["readme"]                = "Readme",
    ["readme.md"]             = "Readme",
    ["readme.txt"]            = "Readme",
    ["todo.md"]               = "Readme",
}


---@param path string
---@param length integer?
---@return string name
---@return string parent
---@return string highlight
M.format_filepath = function(path, length)
    local is_oil = vim.startswith(path, "oil://")
    local highlight
    if is_oil then
        path = path:sub(7, -2)
        highlight = "Directory"
    end
    local parent = M.expand_home(vim.fs.dirname(path), length)
    if parent ~= "/" then
        parent = parent .. "/"
    end

    if not highlight then
        highlight = M.highlight_fname(path)
    end
    local name = vim.fs.basename(path)

    return name, parent, highlight
end
-- }}}

function M.highlight_fname(path, entry, is_hidden)
    if entry then
        path = entry.name
    end

    local name = path:lower() .. (entry and (entry.type == "directory" and "/") or "")
    if name_highlights[name] then
        return "FileType" .. name_highlights[name]
    end

    -- dont try to override directories or links, oil handles them well
    if entry then
        if entry.type == "directory" or entry.type == "link" then
            return
        elseif entry.type == "char" then
            return "FileTypeCharDev"
        elseif entry.type == "block" then
            return "FileTypeBlockDev"
        elseif entry.type == "socket" then
            return "FileTypeSocket"
        end

        if entry.meta.stat and bit.band(entry.meta.stat.mode, 0x49) ~= 0 then
            return "FileTypeExecutable"
        end
    end
    local ext = path:match("%.(%w+)$")
    if ext and extension_highlights[ext] then
        return "FileType" .. extension_highlights[ext]
    end

    if name:sub(-1) == "/" then
        return "Directory"
    end

    if is_hidden then
        return "FileTypeHidden"
    end

    return "FileTypeNormal"
end

-- }}}

-- easier mapping {{{
---@alias nvim_mode_char "n"|"i"|"c"|"v"|"x"|"s"|"o"|"t"
---@alias nvim_mode nvim_mode_char | nvim_mode_char[]

M.map = vim.keymap.set

---@param mode nvim_mode
---@param keys string
---@param opts vim.keymap.del.Opts?
function M.unmap(mode, keys, opts)
    vim.keymap.del(mode, keys, opts or {})
end

---@param bufnr integer
---@param mode nvim_mode
---@param keys string
---@param opts vim.keymap.del.Opts?
function M.lunmap(bufnr, mode, keys, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.del(mode, keys, opts)
end

---@param bufnr integer
---@param mode nvim_mode
---@param keys string
---@param action string|function
---@param opts vim.keymap.set.Opts|nil
function M.lmap(bufnr, mode, keys, action, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, keys, action, opts)
end

M.local_maps = {}

---@param bufnr integer buffer for which to create a local mapper
---@param opts {prefix: string?, group: boolean}?
---@return fun(mode: nvim_mode, keys: string, action: string|function, opts: vim.keymap.set.Opts?)
function M.local_mapper(bufnr, opts)
    opts = opts or {}
    local prefix = opts.prefix

    if opts.group then
        if not M.local_maps[bufnr] then
            M.local_maps[bufnr] = {}
        end
    end

    return function(mode, keys, action, mopts)
        mopts = mopts or {}
        mopts.buffer = bufnr
        keys = prefix and (prefix .. keys) or keys
        if opts.group then
            table.insert(M.local_maps[bufnr], { mode, keys })
        end

        vim.keymap.set(mode, keys, action, mopts)
    end
end

---Unmap all mappings created by a local_mapper with `group = true` for the buffer buf
---@param buf integer Buffer for which local_mapper was created
function M.unmap_group(buf)
    if not M.local_maps[buf] then
        return
    end

    for _, map in ipairs(M.local_maps[buf]) do
        vim.keymap.del(map[1], map[2], { buffer = buf })
    end

    M.local_maps[buf] = nil
end

M.ft_mapper = function()
    local buf = api.nvim_get_current_buf()
    local map = M.local_mapper(buf, { group = true })

    vim.b.undo_ftplugin = ("%s | call v:lua.require'config.utils'.unmap_group(%d)"):format(vim.b.undo_ftplugin, buf)
    return map
end


---@param mode nvim_mode
---@param keys string
---@param string string
function M.abbrev(mode, keys, string)
    if type(mode) == "table" then
        vim.keymap.set(vim.tbl_map(function(s)
            return s .. "a"
        end, mode --[[@as table]]), keys, string)
    else
        vim.keymap.set(mode .. "a", keys, string)
    end
end

-- Mappings that perform an action on a region
M.mode_action = { "n", "v" }
-- Mappings that define a movement
M.mode_motion = { "n", "x", "o" }
-- Mappings that define a textobject region
M.mode_object = { "x", "o" }

---@param fwd function
---@param bwd function
---@return function
---@return function
function M.make_mov_pair(fwd, bwd)
    local fun = require("nvim-treesitter-textobjects.repeatable_move").make_repeatable_move(function(opts)
        if opts.forward then
            fwd()
        else
            bwd()
        end
    end)
    return
        function()
            fun { forward = true }
        end,
        function()
            fun { forward = false }
        end
end

-- }}}

-- Display Windows {{{
---@param args {enter: boolean}
function M.open_window_smart(buffer, args)
    local height = api.nvim_win_get_height(0)
    local width = api.nvim_win_get_width(0)

    return api.nvim_open_win(buffer, args.enter, {
        vertical = height * 2.6 < width
    })
end

---@alias config.win.position
---|"replace"
---|"float"
---|"autosplit"
---|"vertical"
---|"horizontal"
---|"tab"

---@class config.win.opts
---@field position config.win.position?
---@field size [number, number]?
---@field direction "left"|"right"|"above"|"below"?
---@field at_cursor boolean?
---@field title string?

---@param b integer Buffer Number
---@param opts config.win.opts
function M.win_show_buf(b, opts)
    local width, height
    local ewidth, eheight = vim.o.columns, vim.o.lines

    if opts.size then
        width, height = opts.size[1], opts.size[2]

        if width < 1 then
            width = math.floor(ewidth * width)
        else
            width = width
        end

        if height < 1 then
            height = math.floor(eheight * height)
        else
            height = height
        end
    end

    if opts.position == "replace" then
        api.nvim_set_current_buf(b)
    elseif opts.position == "float" then
        width = width or math.floor(ewidth * 0.6)
        height = height or math.floor(eheight * 0.6)

        local row, col
        if opts.at_cursor then
            col = -width
            row = 1
        else
            col = math.floor((ewidth - width) / 2)
            row = math.floor((eheight - height) / 2)
        end

        api.nvim_open_win(b, true, {
            title = opts.title,
            title_pos = opts.title and "center" or nil,
            relative = opts.at_cursor and "cursor" or "editor",
            width = width,
            height = height,
            col = col,
            row = row,
        })
    elseif opts.position == "autosplit" then
        M.open_window_smart(b, { enter = true })
    elseif opts.position == "tab" then
        vim.cmd("tab split #" .. b)
    else
        api.nvim_open_win(b, true, {
            vertical = opts.position == "vertical",
            split = opts.direction,
            width = width,
            height = height
        })
    end

    return api.nvim_get_current_win()
end

-- }}}

-- LSP Symbols {{{
M.lsp_symbols = {
    Array         = "[ arr",
    Boolean       = "? bool",
    Class         = "τ type",
    Cmd           = "",
    Color         = "󰏘 color",
    Constant      = "π const",
    Constructor   = "( init",
    Enum          = "= enum",
    EnumMember    = "- enum",
    Event         = "! ev",
    Field         = ". field",
    File          = "$ file",
    Folder        = "/ dir",
    Function      = "λ func",
    Interface     = "τ type",
    Keyword       = "_ keywd",
    Method        = "λ method",
    Macro         = "# macro",
    Module        = "μ mod",
    Namespace     = ": ns",
    Null          = "?",
    Number        = "¹ num",
    Object        = "{ obj",
    Operator      = "+ op",
    Package       = "μ pkg",
    Property      = ": prop",
    Reference     = "󰌷 ref",
    Snippet       = " snip",
    String        = '" str',
    Struct        = "{ struct",
    Text          = '" txt',
    TypeParameter = "τ (type)",
    Unit          = "@ unit",
    Value         = "1 val",
    Variable      = "α var",
}

M.lsp_highlights = {
    Array         = "@variable",
    Boolean       = "@variable",
    Class         = "@type",
    Color         = "@symbol",
    Constant      = "@constant",
    Constructor   = "@constructor",
    Enum          = "@constant",
    EnumMember    = "@macro",
    Event         = "@constant",
    Field         = "@property",
    Function      = "@function",
    Interface     = "@type",
    Keyword       = "@keyword",
    Macro         = "@macro",
    Method        = "@function",
    Module        = "@module",
    Null          = "@variable",
    Number        = "@variable",
    Object        = "@variable",
    Operator      = "@operator",
    Package       = "@module",
    Namespace     = "@variable",
    Property      = "@property",
    Snippet       = "@constant",
    String        = "@variable",
    Struct        = "@type",
    Text          = "@string",
    TypeParameter = "@type",
    Unit          = "@symbol",
    Value         = "@number",
    Variable      = "@variable",
}
-- }}}

-- Autocommands {{{
---@param name string
---@param commands table<string|string[], function|vim.api.keyset.create_autocmd>
---@param opts {buf: integer}?
M.autogroup = function(name, commands, opts)
    opts = opts or {}
    local group = api.nvim_create_augroup(name, { clear = true })

    for ev, cfg in pairs(commands) do
        local tbl
        if type(cfg) == "function" then
            tbl = { callback = cfg }
        else
            tbl = cfg
        end
        tbl.group = group
        tbl.buffer = opts.buf

        api.nvim_create_autocmd(ev, tbl)
    end

    return group
end

---@param name string
---@param commands table<string|string[], function>
M.user_autogroup = function(name, commands)
    local group = api.nvim_create_augroup(name, { clear = true })

    for ev, cb in pairs(commands) do
        local tbl = { pattern = ev, callback = cb, group = group }

        api.nvim_create_autocmd("User", tbl)
    end
end

---@param group string
---@param event string|string[]
M.del_autocommand = function(group, event)
    local commands = api.nvim_get_autocmds { group = group, event = event }
    api.nvim_del_autocmd(commands[1].id)
end
-- }}}

-- Format Dates & Times {{{
M.highlight_time = function(secs)
    local cur_time = os.time()

    return M.highlight_timedelta(cur_time - secs)
end
M.highlight_timedelta = function(secs)
    if secs < 3600 then
        return "FileTimeLastHour"
    elseif secs < 86400 then
        return "FileTimeLastDay"
    elseif secs < 604800 then
        return "FileTimeLastWeek"
    elseif secs < 1209600 then
        return "FileTimeLastFortnight"
    elseif secs < 2592000 then
        return "FileTimeLastMonth"
    elseif secs < 22896000 then
        return "FileTimeLastYear"
    else
        return "FileTimeOld"
    end
end

-- NOTE: all of these formats take up the same space
-- and importantly for Oil, the main user of this, two WORDs
local day_fmt = "Tdy %H:%M"   -- Tdy 20:10
local week_fmt = "%a %H:%M"   -- Mon 10:11
local month_fmt = "%d. %H:%M" -- 10. 10:11
local year_fmt = "%b %d'%H"   -- Nov 26'11
local older_fmt = "%b/%y %d"  -- Oct/24 06

---@param secs integer
---@return [string, string]
M.format_time_smart = function(secs)
    local now = os.time()
    local delta = now - secs
    local timeinfo = os.date("*t", secs)
    local nowinfo = os.date("*t", now)

    local formatted
    if
        timeinfo.day == nowinfo.day
        and timeinfo.month == nowinfo.month
        and timeinfo.year == nowinfo.year then
        formatted = os.date(day_fmt, secs)
    elseif delta < 518400 then
        formatted = os.date(week_fmt, secs)
    elseif
        timeinfo.month == nowinfo.month
        and timeinfo.year == nowinfo.year then
        formatted = os.date(month_fmt, secs)
    elseif timeinfo.year == nowinfo.year then
        formatted = os.date(year_fmt, secs)
    else
        formatted = os.date(older_fmt, secs)
    end

    local hl = M.highlight_timedelta(delta)

    return { formatted, hl }
end

M.smart_date_len = #day_fmt
-- }}}

-- Format numbers {{{

--- Give bigger files scarier colors based on how bad of an idea it would be to open them in Neovim
---@param bytes integer
---@return string
M.highlight_size = function(bytes)
    if bytes == 0 then
        return "FileSizeNone"
    elseif bytes < 16384 then    -- 16K
        return "FileSizeNormal"
    elseif bytes < 65536 then    -- 64K
        return "FileSizeMedium"
    elseif bytes < 262144 then   -- 256K
        return "FileSizeLarge"
    elseif bytes < 10485760 then -- 10M
        return "FileSizeHuge"
    else                         -- Anything bigger is a colossal mistake
        return "FileSizeTooBig"
    end
end

---@param count integer
---@param size integer? By default a prefix size of 1000 (SI) is used
---@return string
M.format_size = function(count, size)
    size = size or 1000
    if count < size then
        return tostring(count)
    end

    local sizes = {
        "", "k", "m", "g", "t"
    }

    local i = 1
    while count >= size do
        count = count / size
        i = i + 1
    end

    return ("%.1f%s"):format(count, sizes[i])
end

---@param num integer num > 0
---@param upper boolean Use Uppercase
---@return string Roman Numeral
M.format_roman = function(num, upper)
    local arabic = { 1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1 }
    local roman = { "m", "cm", "d", "cd", "c", "xc", "l", "xl", "x", "ix", "v", "iv", "i" }

    local res = require("string.buffer").new(100)
    for i = 1, #arabic do
        while arabic[i] <= num do
            num = num - arabic[i]
            res:put(roman[i])
        end
    end

    local out = res:tostring()
    return upper and out:upper() or out
end

M.format_bin = function(n)
    local buf = string_buffer.new(16)
    buf:put("0b")
    local nbits = math.max(1, select(2, math.frexp(n)))
    for i = nbits, 1, -1 do
        local b = bit.band(n, bit.lshift(1, i - 1))
        buf:put(b == 0 and "0" or "1")
    end

    return tostring(buf)
end

M.format_raised = function(num)
    local chars = {
        ["0"] = "⁰",
        ["1"] = "¹",
        ["2"] = "²",
        ["3"] = "³",
        ["4"] = "⁴",
        ["5"] = "⁵",
        ["6"] = "⁶",
        ["7"] = "⁶",
        ["8"] = "⁷",
        ["9"] = "⁸",
    }

    return tostring(num):gsub(".", chars)
end
-- }}}

-- Ranges {{{
M.get_cur_line_range = function()
    local mode = fn.mode(1)
    if mode == "v" or mode == "V" then
        local vline = fn.getpos("v")[2]
        local cline = fn.getpos(".")[2]

        if vline > cline then
            return cline, vline
        else
            return vline, cline
        end
    end

    local lnum = api.nvim_win_get_cursor(0)[1]
    return lnum, lnum
end
-- }}}

---@param buf integer
M.buf_drop_undo = function(buf)
    local bo = vim.bo[buf]
    local oldlevels = bo.undolevels
    bo.undolevels = -1
    vim.cmd("normal! a" .. vim.keycode " <bs>")
    bo.undolevels = oldlevels
end

-- Messages {{{
---@param subsystem string
---@param message string
M.message = function(subsystem, message)
    api.nvim_echo({
        { ("[%s]"):format(subsystem), "Identifier" }, { ": ", "NonText" }, { message }
    }, false, {})
end

---@param subsystem string
---@param message string
M.warn = function(subsystem, message)
    api.nvim_echo({
        { ("[%s]"):format(subsystem), "WarningMsg" }, { ": ", "NonText" }, { message }
    }, false, {})
end
---@param subsystem string
---@param message string
---@param drop_errno boolean?
M.error = function(subsystem, message, drop_errno)
    if drop_errno then
        message = message:gsub("^Vim:E%d+:%s*", "")
    end
    api.nvim_echo({
        { ("[%s]"):format(subsystem), "ErrorMsg" }, { ": ", "NonText" }, { message }
    }, false, {})
end
-- }}}

return M
