local M = {}
local fn = vim.fn
local api = vim.api
local ns = api.nvim_create_namespace("config.ui")
M.ns = ns
local utils = require("config.utils")
local string_buffer = require("string.buffer")

local cur_completion
M.nvim_input_omnifunc = function(start, base)
    local compl = cur_completion
    if not compl then
        return start == 1 and 0 or {}
    end
    if start == 1 then
        return 0
    end

    local parts = vim.split(compl, ",", { plain = true })
    local ret
    if parts[1] == "custom" or parts[1] == "customlist" then
        local func = parts[2]
        if vim.startswith(func, "v:lua.") then
            local lua_to_load = ("return %s(...)"):format(func:sub(7))
            local luafunc, err = loadstring(lua_to_load)
            if not luafunc then
                vim.notify(("Failed to load lua omnifunc '%s': %s"):format(lua_to_load, err), vim.log.levels.ERROR)
                return {}
            end

            ret = luafunc(base, base, fn.strlen(base))
        else
            ret = fn[func](base, base, fn.strlen(base))
        end
        if parts[1] == "custom" then
            ret = vim.split(ret, "\n", { plain = true })
        end

        return ret
    end

    local ok, result = pcall(fn.getcompletion, base, compl)
    if ok then
        return result
    else
        return {}
    end
end

local last_was_insert

--[[ vim.ui.input implementation
WARNING: This is *not* 100% what neovim says it should be, instead I add my own private features,
starting with an underscore:
  _ts_lang: highlight the buffer using that treesitter language
]] --
---@param opts {prompt: string?, default: string?, completion: string?, highlight: function, _ts_lang: string?}
---@param callback fun(string?)
M.nvim_input = function(opts, callback)
    last_was_insert = api.nvim_get_mode().mode:find("[it]") and true or false

    local buf = api.nvim_create_buf(false, true)
    local title = opts.prompt and opts.prompt:gsub("%s*:%s*", "") or "Input"

    if opts.default then
        api.nvim_buf_set_lines(buf, 0, 0, false, { opts.default })
    end

    api.nvim_buf_set_name(buf, "[Input]")
    local bo = vim.bo[buf]
    bo.filetype = "Input"
    bo.swapfile = false
    bo.bufhidden = "wipe"
    bo.omnifunc = "v:lua.require'config.ui'.nvim_input_omnifunc"
    cur_completion = opts.completion

    local lines = vim.o.lines
    local columns = vim.o.columns
    local win = api.nvim_open_win(buf, true, {
        title = title,
        relative = "editor",
        anchor = "SW",
        style = "minimal",
        row = lines - 2,
        col = 0,
        width = math.max(40, math.min(16, math.floor(columns * 0.3))),
        height = 1,
    })

    -- HACK: add my own extension
    if opts._ts_lang then
        vim.treesitter.start(buf, opts._ts_lang)
    end

    local augroup
    local clean = function()
        api.nvim_del_augroup_by_id(augroup)
        pcall(api.nvim_win_close, win, true)
        pcall(api.nvim_buf_delete, win, { force = true })
        if last_was_insert then
            vim.cmd.startinsert()
        else
            vim.cmd.stopinsert()
        end
    end
    local cancel = function()
        callback(nil)
        clean()
    end
    local confirm = function()
        local text = api.nvim_buf_get_lines(buf, 0, -1, false)[1]
        callback(text)
        clean()
    end

    augroup = utils.autogroup("config.ui.input." .. buf, {
        BufLeave                            = cancel,
        [{ "TextChanged", "TextChangedI" }] = function()
            local txt = api.nvim_buf_get_lines(buf, 0, 1, true)[1]
            local hls = {}

            if type(opts.highlight) == "function" then
                hls = opts.highlight(txt)
            elseif opts.highlight then
                hls = fn[opts.highlight](txt)
            end

            api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            for _, hl in ipairs(hls) do
                api.nvim_buf_set_extmark(buf, ns, 0, hl[1], {
                    end_line = 0,
                    end_col = hl[2],
                    hl_group = hl[3],
                })
            end
        end
    }, { buf = buf })
    local map = function(mode, lhs, rhs, map_opts)
        map_opts = map_opts or {}
        map_opts.buffer = buf
        vim.keymap.set(mode, lhs, rhs, map_opts)
    end

    map({ "i", "n" }, "<cr>", confirm)
    map({ "n" }, "<esc>", confirm)
    map({ "i", "s" }, "<Tab>", "<C-n>", { remap = true })

    if not opts.default or opts.default:match("^%s*$") then
        vim.cmd.startinsert()
    end
end


---@class config.ui.notif_opts
---@field max_width integer
---@field align "left"|"right"
---@field name string

---@type table<integer, {win: integer, opts: config.ui.notif_opts}>
M.floating_notifs = {}

M.shown_floating_notifs = 0

---@param opts config.ui.notif_opts
---@return integer Buffer/Id
M.floating_notif_new = function(opts)
    local buf = api.nvim_create_buf(false, true)
    M.floating_notifs[buf] = {
        opts = opts,
    }

    return buf
end

---@param id integer
M.floating_notif_delete = function(id)
    M.floating_notifs[id] = nil
    api.nvim_buf_delete(id, { force = true })
end

---@param id integer
---@param text ([string, string])[]
M.floating_notif_put = function(id, text)
    if not api.nvim_buf_is_valid(id) then
        M.floating_notifs[id] = nil
        return
    end
    api.nvim_buf_clear_namespace(id, ns, 0, 1)
    local obj = M.floating_notifs[id]
    if not obj.win then
        obj.win = api.nvim_open_win(id, false, {
            relative = "editor",
            style = "minimal",
            row = M.shown_floating_notifs + 1,
            col = obj.opts.align == "right" and vim.o.columns or 0,
            height = 1,
            width = obj.opts.max_width,
            border = "none",
            focusable = false,
            mouse = false
        })
        vim.wo[obj.win].winblend = 20
        M.shown_floating_notifs = M.shown_floating_notifs + 1
    end
    api.nvim_buf_set_extmark(id, ns, 0, 0, {
        virt_text = text,
        virt_text_pos = obj.opts.align == "right" and "eol_right_align" or nil,
    })
end

M.floating_notif_hide = function(id)
    local obj = M.floating_notifs[id]
    if not obj then
        return
    end
    if obj.win then
        pcall(api.nvim_win_close, obj.win, true)
        obj.win = nil
        M.shown_floating_notifs = M.shown_floating_notifs - 1
    end
end

---@alias config.ui.select_item {key: string, desc: string, value: any}

---@generic T
---@param prompt string
---@param items config.ui.select_item[]
---@return T?
M.select = function(prompt, items)
    local count = #items
    local width = vim.o.columns
    local items_per_line = math.floor(width / 20)

    local key_lookup = {}
    for _, v in ipairs(items) do
        key_lookup[vim.keycode(v.key)] = v.value or v.key
    end

    local line_buf = string_buffer.new(width)
    local lines = {}
    local highlights = {}
    for i = 1, math.ceil(count / items_per_line) do
        for j = 1, items_per_line do
            local item = items[items_per_line * (i - 1) + j]
            if item then
                local text = ("%6s %-13s"):format(item.key, item.desc)
                local kstart = 20 * (j - 1)
                local kstop = kstart + 6
                table.insert(highlights, { i - 1, kstart + (6 - #item.key), kstop, "@comment.note" })
                table.insert(highlights, { i - 1, kstop + 1, kstop + 13, "@text.emphasis" })
                line_buf:put(text)
            else
                break
            end
        end
        table.insert(lines, line_buf:tostring())

        line_buf:reset()
    end

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for _, hl in ipairs(highlights) do
        api.nvim_buf_set_extmark(buf, ns, hl[1], hl[2], {
            end_col = hl[3],
            hl_group = hl[4]
        })
    end

    local win = api.nvim_open_win(buf, false, {
        title = prompt,
        title_pos = "center",
        style = "minimal",
        relative = "laststatus",
        anchor = "SW",
        col = 0,
        row = 0,
        width = width,
        height = #lines
    })

    vim.cmd.redraw()
    local key = vim.fn.getcharstr(-1, { cursor = "hide", simplify = false })
    api.nvim_win_close(win, true)

    return key_lookup[key]
end

return M
