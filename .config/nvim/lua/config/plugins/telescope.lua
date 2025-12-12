local M = {}

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")

-- Layouts {{{
local t_layout = require("telescope.pickers.layout")

-- Helpers {{{
local make_win = function(enter, opts)
    local buf = api.nvim_create_buf(false, true)
    local winopts = vim.tbl_extend("force", {
        style = "minimal",
        zindex = 200,
        anchor = "SW",
        relative = "editor",
    }, opts)
    local win = api.nvim_open_win(buf, enter, winopts)

    return t_layout.Window {
        bufnr = buf,
        winid = win,
    }
end

local make_windows = function(results_conf, preview_conf, prompt_conf)
    return make_win(false, results_conf), preview_conf and make_win(false, preview_conf), make_win(true, prompt_conf)
end

local destroy_win = function(win)
    if win then
        if api.nvim_win_is_valid(win.winid) then
            api.nvim_win_close(win.winid, true)
        end
        if api.nvim_buf_is_valid(win.bufnr) then
            api.nvim_buf_delete(win.bufnr, { force = true })
        end
    end
end

local get_layout = function(value, full, percentage, min, max)
    if value then
        if type(value) == "function" then
            return value()
        else
            return value
        end
    end

    local val = math.floor(percentage * (full))
    return math.max(min, math.min(max, val))
end
-- }}}

-- Bottom Pane, Similar to Ivy {{{
M.bottom_pane_layout = function(picker)
    return t_layout {
        picker = picker,
        mount = function(self)
            local width = vim.o.columns
            local factor = 0.45
            local fhalf = math.floor(width * (factor))
            local shalf = math.floor(width * (1 - factor))

            if (fhalf + shalf) ~= width then
                fhalf = fhalf + 1
            end

            local height = vim.o.lines
            local view_height = get_layout(self.picker.layout_config.height, height - 4, 0.4, 8, 30)

            local row = height - 2

            self.results, self.preview, self.prompt = make_windows({
                row = row,
                col = 0,
                width = fhalf,
                height = view_height,
                border = { "─", "─", "─", " ", "", "", "", "" },
            }, {
                row = row,
                col = fhalf + 2,
                width = shalf - 2,
                height = view_height,
                border = { "┬", "─", "─", "", "", "", "", "│" },
            }, {
                width = fhalf,
                height = 1,
                row = height,
                col = 0,
                border = "none",
            })
        end,
        unmount = function(self)
            destroy_win(self.results)
            destroy_win(self.preview)
            destroy_win(self.prompt)
        end,
        update = function(self)
        end
    }
end
-- }}}

-- Smaller, for use without preview {{{
M.short_layout = function(picker)
    return t_layout {
        mount = function(self)
            local columns = vim.o.columns
            local lines = vim.o.lines

            local height = picker.layout_config.height or 12
            if type(height) == "function" then
                height = height()
            end

            local width = get_layout(picker.layout_config.width, columns, 0.4, 32, 80)

            self.results, _, self.prompt = make_windows({
                row = lines - 2,
                col = 0,
                width = width,
                height = height,
                border = { "╭", "─", "╮", "│", "", "", "", "" },
            }, nil, {
                row = lines + 1,
                col = 0,
                width = width,
                height = 1,
                border = "none"
            })
        end,
        unmount = function(self)
            destroy_win(self.results)
            destroy_win(self.prompt)
        end,
        update = function(self)
        end
    }
end
-- }}}
-- }}}

local MAX_FILENAME_WIDTH = 32
local MAX_SYMBOL_WIDTH = 30
local ROW_COL_WIDTH = 7

-- Path Highlighting {{{
M.path_display = function(opts, path)
    local tail = fn.fnamemodify(path, ":t")
    local parendir = fn.pathshorten(fn.fnamemodify(path, ":~:.:h"), 6)

    local namelen = #tail
    local namewidth = fn.strdisplaywidth(tail)
    local dirlen = #parendir

    local padding = math.floor(math.max(MAX_FILENAME_WIDTH * 1.3 - namewidth, 0))
    local hl = utils.highlight_fname(tail)
    if hl == "FileTypeNormal" then
        hl = nil
    end

    local hls = {
        {
            {
                0,
                namelen,
            },
            ""
        },
        {
            {
                namelen + 1 + padding,
                namelen + dirlen + 1 + padding,
            },
            "NonText"
        }
    }

    return string.format("%s %s%s ", tail, (" "):rep(padding), parendir), hls
end
-- }}}

-- Helpers {{{
local t_entry_display = require("telescope.pickers.entry_display")

local get_names_and_hl = function(path)
    local tail, parentdir, filename_highlight
    if vim.startswith(path, "oil://") then
        path = path:sub(#"oil://" + 1, -2)
        tail = fn.fnamemodify(path, ":t") .. "/"
        parentdir = fn.pathshorten(fn.fnamemodify(path, ":~:.:h"), 6)
        filename_highlight = "Directory"
    else
        tail = fn.fnamemodify(path, ":t")
        parentdir = fn.pathshorten(fn.fnamemodify(path, ":~:.:h"), 6)
        filename_highlight = utils.highlight_fname(tail)
    end

    if filename_highlight == "FileTypeNormal" then
        filename_highlight = nil
    end

    return tail, parentdir, filename_highlight
end
-- }}}

-- Grep-Style {{{
local line_and_column_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = 4 },
        { width = 40 },
        { width = MAX_FILENAME_WIDTH * 0.9 },
        { remaining = true }
    }
}
M.line_and_column_entries = function(line)
    local _, _, filename, row, col, text = string.find(line, "(..-):(%d+):(%d+):(.*)")
    row, col = tonumber(row), tonumber(col)

    return {
        value = line,
        display = function()
            local tail, parentdir, filename_highlight = get_names_and_hl(filename)

            return line_and_column_display {
                { ("%d"):format(row), "LineNr" },
                { vim.trim(text) },
                { tail,               filename_highlight },
                { parentdir,          "NonText" },
            }
        end,
        ordinal = string.format("%s:%s:%d", text, filename, row),
        lnum = row,
        col = col,
        filename = filename
    }
end
-- }}}

-- Plain File Names {{{
local file_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = MAX_FILENAME_WIDTH * 1.4 },
        { width = utils.datefmt.short_len },
        { remaining = true,                right_justify = true },
    }
}

local file_entry_display = function(entry)
    local value = entry.value
    local st = entry.st

    local tail, parentdir, filename_highlight = get_names_and_hl(value)
    local mtime, timehl
    if not st then
        mtime = ""
        timehl = ""
    else
        mtime = utils.datefmt.fmt_short(st.mtime.sec)
        timehl = utils.highlight_time(st.mtime.sec)
    end

    return file_display {
        { tail,      filename_highlight },
        { mtime,     timehl },
        { parentdir, "NonText" }
    }
end

M.file_entries = function(entry)
    return {
        value = entry,
        st = entry and vim.uv.fs_stat(entry) or nil,
        display = file_entry_display,
        filename = entry,
        ordinal = entry,
    }
end
-- }}}

-- LSP Symbols {{{
local lsp_entry_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = MAX_SYMBOL_WIDTH },
        { width = 8 }, -- icon and type
        { width = MAX_FILENAME_WIDTH },
        { remaining = true }
    }
}
M.lsp_symbol_entries = function(entry)
    local buf
    if not entry.filename then
        buf = vim.api.nvim_get_current_buf()
    end

    local filename = entry.filename or vim.api.nvim_buf_get_name(buf)
    local _, name = entry.text:match("^%[(.+)%]%s+(.*)")

    -- ignore
    if
        name:match("^%[?%d+%]?$")      -- indices in arrays
        or name == "(anonymous union)" -- thx clangd...
        or name == "(anonymous struct)"
        or entry.kind == "Null"        -- wtf
        or entry.kind == "Package"
        or entry.kind == "Field"       -- fields in structures
        or entry.kind == "EnumMember"  -- members of enums
    then
        return
    end

    return {
        col = entry.col,
        lnum = entry.lnum,
        symbol_type = entry.kind,
        buffer = buf,
        filename = filename,
        value = entry,
        ordinal = string.format("%s:%s:%s:%d", entry.kind, name, filename, entry.lnum),
        display = function()
            -- use same highlights as completion
            local hl = "BlinkCmpKind" .. entry.kind
            local tail, parentdir, filename_highlight = get_names_and_hl(filename)

            return lsp_entry_display {
                { name,                                        utils.lsp_highlights[entry.kind] },
                { utils.lsp_symbols[entry.kind] or entry.kind, hl },
                { tail,                                        filename_highlight },
                { parentdir,                                   "NonText" }
            }
        end
    }
end
-- }}}

-- Quickfix List {{{
local quickfix_entry_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = 4 },
        { width = 40 },
        { width = MAX_FILENAME_WIDTH },
        { remaining = true },
    }
}

M.quickfix_entries = function(entry)
    local filename = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr or 0)
    return {
        value = entry,
        ordinal = ("%s:%s:%d"):format(entry.text, filename, entry.lnum),
        bufnr = entry.bufnr,
        filename = filename,
        col = entry.col,
        lnum = entry.lnum,
        text = entry.text,
        display = function()
            local tail, parentdir, filename_highlight = get_names_and_hl(filename)
            return quickfix_entry_display {
                { ("%d"):format(entry.lnum), "LineNr" },
                { entry.text },
                { tail,                      filename_highlight },
                { parentdir,                 "NonText" },
            }
        end
    }
end
-- }}}

-- Buffer List {{{
local buffer_entry_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = 2 },                  -- shorthand number
        { width = 3 },                  -- "real" number
        { width = 1 },                  -- status.hidden
        { width = 4 },                  -- status.readonly
        { width = 1 },                  -- status.modified
        { width = 1 },                  -- buffer kind
        { width = 5 },                  -- line
        { width = MAX_FILENAME_WIDTH }, -- buffer name
        { remaining = true },           -- directory
    }
}
M.buffer_entries = function(entry)
    local buf = entry.bufnr
    local shortbuf = Short_for_bufs[buf]
    local name, kind, show_modified = utils.format_buf_name(buf)
    local kindicon = utils.btypesymbols[kind]

    local tail, parent, hl = name, "", ""

    if kind == "oil" then
        local bname = api.nvim_buf_get_name(buf):gsub("^oil://", "")
        tail = utils.expand_home(bname, 8)
        parent = bname
        hl = "Directory"
    elseif vim.bo[buf].buftype == "" and name then
        tail, parent, hl = get_names_and_hl(name)
    elseif not name then
        tail = "[-]"
        hl = "NonText"
    end

    local filename = entry.info.name ~= "" and entry.info.name or nil
    local lnum = entry.info.lnum ~= 0 and entry.info.lnum or 1

    return {
        value = name,
        path = filename,
        lnum = lnum,
        bufnr = buf,
        ordinal = string.format("%s:%s:%d:%d", kindicon, name, shortbuf or 0, buf),
        display = function()
            return buffer_entry_display {
                { shortbuf or "nil",                    shortbuf and "Identifier" or "NonText" },
                { buf,                                  "Number" },
                { entry.info.hidden == 1 and "." or "", entry.info.hidden == 1 and "NonText" },
                (vim.bo[buf].readonly
                    and { "[ro]", "NonText" }
                    or { "[rw]", "String" }),
                { entry.info.changed == 1 and show_modified and "~" or "", "Constant" },
                { kindicon,                                                "SlI" .. utils.btypehighlights[kind] },
                { ":" .. lnum,                                             "Number" },
                { tail,                                                    hl },
                { parent,                                                  "NonText" }
            }
        end
    }
end
-- }}}

-- Diagnostics {{{
local diagnostics_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = 1 },                -- symbol: W|H|I|E etc
        { width = MAX_SYMBOL_WIDTH }, -- message
        { width = 9 },                -- row:col
        { width = MAX_FILENAME_WIDTH },
        { remaining = true }
    }
}
M.diagnostics_entries = function(entry)
    local type = entry.type:sub(1, 1)

    -- lots of lsps suggest fixes there
    local text = entry.text:gsub("%s*%(.*%)%s*$", "")

    return {
        value = entry,
        filename = entry.filename,
        type = type,
        qf_type = type,
        lnum = entry.lnum,
        col = entry.col,
        text = text,
        ordinal = ("%s:%s:%s"):format(type, entry.filename, entry.text),
        display = function()
            local tail, parentdir, filename_highlight = get_names_and_hl(entry.filename)
            return diagnostics_display {
                { type,                                          "DiagnosticSign" .. entry.type },
                { text },
                { string.format("%d:%d", entry.lnum, entry.col), "Number" },
                { tail,                                          filename_highlight },
                { parentdir,                                     "NonText" },
            }
        end,
    }
end

-- Registers {{{
local register_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = 1 },       -- name
        { remaining = true } -- content
    }
}
M.register_entries = function(entry)
    local content = vim.fn.getreg(entry, 1)
    local byte = string.byte(entry)
    local ischar = byte >= 65 and byte <= 90
    if ischar then
        entry = entry:lower()
    end
    local isnum = byte >= 48 and byte <= 57

    local text = type(content) == "string" and vim.trim(content:gsub("\n", "\x0d")) or content
    local texthl
    if #content == 0 then
        text = "[empty]"
        texthl = "NonText"
    end

    return {
        value = entry,
        ordinal = ("%s %s"):format(entry, text),
        content = content,
        display = function()
            return register_display {
                { entry, ischar and "String" or (isnum and "Number" or "Identifier") },
                -- { description, "Comment" },
                { text,  texthl }
            }
        end
    }
end
-- }}}

-- Treesitter {{{
local treesitter_display = t_entry_display.create {
    separator = " ",
    items = {
        { width = MAX_SYMBOL_WIDTH },
        { width = ROW_COL_WIDTH },
        { width = 8 },
        { remaining = true }
    }
}

local ts_to_lsp_kind = {
    ["associated"] = "Object",
    ["parameter"]  = "Variable",
    ["var"]        = "Variable",
}

local last_ts_tuple = {}
M.treesitter_entries = function(entry)
    local srow, scol, erow, ecol = vim.treesitter.get_node_range(entry.node)

    local buf = api.nvim_get_current_buf()
    if last_ts_tuple[1] ~= buf then
        last_ts_tuple[1] = buf
        last_ts_tuple[2] = api.nvim_buf_get_name(buf)
    end

    local text = vim.treesitter.get_node_text(entry.node, buf)

    local lsp_kind = ts_to_lsp_kind[entry.kind] or (entry.kind:sub(1, 1):upper() .. entry.kind:sub(2))
    return {
        value = entry.node,
        kind = lsp_kind,
        ordinal = text .. " " .. (entry.kind or "unknown"),
        lnum = srow + 1,
        buf = last_ts_tuple[1],
        filename = last_ts_tuple[2],
        col = scol,
        start = srow,
        finish = erow,
        display = function()
            return treesitter_display {
                { text,                                      utils.lsp_highlights[lsp_kind] },
                { ("%d:%d"):format(srow, scol),              "Number" },
                { utils.lsp_symbols[lsp_kind] or entry.kind, "BlinkCmpKind" .. (lsp_kind or "a") },
            }
        end
    }
end
-- }}}
-- }}}

-- Actions {{{
local t_actions = require("telescope.actions")
local t_action_state = require("telescope.actions.state")
local t_builtins = require("telescope.builtin")

M.edit_register = function(buf)
    t_actions.close(buf)

    local selection = t_action_state.get_selected_entry()
    local text = selection.content:gsub("\n", "\x0d")
    local reg = selection.value

    local edit_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(edit_buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
    local win = utils.win_show_buf(edit_buf, {
        position = "float",
        title = "Edit \"" .. reg
    })

    vim.keymap.set("n", "<cr>", function()
        local new_text = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false)
        vim.api.nvim_win_close(win, true)
        vim.fn.setreg(reg, new_text)
        t_builtins.registers()
    end, { buffer = edit_buf })
end

M.select_register = function(buf)
    t_actions.close(buf)

    local selection = t_action_state.get_selected_entry()
    local reg = selection.value

    api.nvim_feedkeys("\"" .. reg, "n")
end

-- Open all selected files
M.select_all_or_one = function(buf)
    ---@type Picker
    local picker = t_action_state.get_current_picker(buf)
    local multi = picker:get_multi_selection()
    if not vim.tbl_isempty(multi) then
        t_actions.close(buf)
        for i, file in ipairs(multi) do
            if file.filename then
                local cmd = (i == 1 and "edit " or "Split ") .. (file.lnum
                    and ("+%d %s"):format(file.lnum, file.filename)
                    or file.filename)
                vim.cmd(cmd)
            end
        end
    else
        t_actions.select_default(buf)
    end
end

M.multi_select_visible = function(buf)
    ---@type Picker
    local picker = t_action_state.get_current_picker(buf)
    local visible = picker.manager.info.displayed
    for i = 1, visible do
        local index = picker:get_index(i)
        picker:toggle_selection(index)
    end
end

--- View a commit in fugitive
M.fugitive_commit = function(buf)
    local selection = t_action_state.get_selected_entry()
    t_actions.close(buf)

    vim.cmd.Gedit(selection.value)
end
-- }}}

-- Pickers {{{
local t_pickers = require("telescope.pickers")
local t_finders = require("telescope.finders")
local t_config = require("telescope.config").values


M.jumplist = function(opts)
    opts = opts or {}
    local jumplist = fn.getjumplist()[1]

    local list = {}
    for i = #jumplist, 1, -1 do
        local jump = jumplist[i]
        table.insert(list, {
            buf = jump.bufnr,
            col = jump.col,
            lnum = jump.lnum,
            text = (api.nvim_buf_is_valid(jump.bufnr)
                and api.nvim_buf_get_lines(jump.bufnr, jump.lnum - 1, jump.lnum, false)[1]
                or "")
        })
    end

    t_pickers.new(opts, {
        prompt_title = "Jumplist",
        sorter = t_config.generic_sorter(opts),
        previewer = t_config.qflist_previewer(opts),
        finder = t_finders.new_table {
            entry_maker = M.quickfix_entries,
            results = list
        }
    }):find()
end
-- }}}

return M
