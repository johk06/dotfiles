local M = {}
local api = vim.api
local fn = vim.fn
local ns = api.nvim_create_namespace("config.ui")
M.ns = ns
local utils = require("config.utils")

--[[ vim.ui.input implementation {{{
NOTE: This is *not* 100% what neovim says it should be, instead I add my own private features,
starting with an underscore:
- _ts_lang: highlight the buffer using that treesitter language
- completion can be a function
]]
---@class config.ui.input_opts
---@field prompt string?
---@field default string?
---@field completion string|function? Custom extension
---@field highlight function?
---@field _ts_lang string? Custom extension
---@type string|function

---@type string|function
local cur_input_completion
local input_omnifunc_decl = "v:lua.require'config.lib.ui'.nvim_input_omnifunc"
M.nvim_input_omnifunc = function(start, base)
    local compl = cur_input_completion
    if not compl then
        return start == 1 and 0 or {}
    end

    if start == 1 then
        return 0
    end

    -- My extension, completion is a regular lua function
    if type(compl) == "function" then
        local ok, result = pcall(compl, start, base)
        if ok then
            return result
        else
            return {}
        end
    end

    ---@cast compl string
    local parts = vim.split(compl, ",", { plain = true })
    local ret
    if parts[1] == "custom" or parts[1] == "customlist" then
        local func = table.concat(parts, ",", 2)

        if vim.startswith(func, "v:lua.") then
            -- v:lua.some_module_function
            local lua_to_load = ("return %s(...)"):format(func:sub(7))
            local luafunc, err = loadstring(lua_to_load)
            if not luafunc then
                utils.error("Input", ("Failed to load lua omnifunc '%s': %s"):format(lua_to_load, err))
                return {}
            end

            ret = luafunc(base, #base)
        else
            -- regular vimscript function
            ret = fn[func](base, #base)
        end
        -- :h :command-completion-custom returns a newline separated string
        if parts[1] == "custom" then
            ret = vim.split(ret, "\n", { plain = true })
        end

        return ret
    end

    -- it's a different, string-based :h :command-completion
    local ok, result = pcall(fn.getcompletion, base, compl)
    if ok then
        return result
    else
        return {}
    end
end

---@param cb fun(string?)
---@param text string
local confirm_text = function(cb, text)
    vim.schedule(function()
        cb(text)
    end)
end

local last_was_insert

---Edit vim.ui.input in a full-fat window
---@param cb fun(string?)
---@param content string
---@param prompt string
---@param opts config.ui.input_opts
local expand_ui_input = function(cb, content, prompt, opts)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(buf, ("[Input: %s]"):format(prompt))
    api.nvim_buf_set_lines(buf, 0, 1, false, { content })

    local win = utils.win_show_buf(buf, {
        position = "float",
        title = prompt
    })

    local bo = vim.bo[buf]
    bo.buftype = "acwrite"
    bo.modified = false
    bo.omnifunc = input_omnifunc_decl
    bo.ft = "Input"
    if opts._ts_lang then
        vim.treesitter.start(buf, opts._ts_lang)
    end

    local augroup
    local clean = function()
        pcall(api.nvim_win_close, win)
        pcall(api.nvim_buf_delete, buf, { force = true })
        api.nvim_del_augroup_by_id(augroup)
    end

    local wrote_at_least_once = false
    augroup = utils.autogroup("config.ui.input-expanded.#" .. buf, {
        BufWriteCmd = {
            buffer = buf,
            callback = function()
                bo.modified = false
                wrote_at_least_once = true
            end
        },
        BufLeave = {
            buffer = buf,
            callback = function()
                if not bo.modified and wrote_at_least_once then
                    local text = table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), " ")
                    confirm_text(cb, text)
                else
                    cb(nil)
                end
                clean()
            end
        }
    })
end

---@param opts config.ui.input_opts
---@param callback fun(string?)
M.nvim_input = function(opts, callback)
    last_was_insert = api.nvim_get_mode().mode:find("[it]") and true or false

    local buf = api.nvim_create_buf(false, true)
    local titlebuf = api.nvim_create_buf(false, true)

    if opts.default and opts.default:match("%S") then
        api.nvim_buf_set_lines(buf, 0, 0, false, { opts.default })
    else
        api.nvim_buf_set_lines(buf, 0, 0, false, { "" })
    end

    local title = (opts.prompt and opts.prompt:gsub("%s*:%s*", "") or "Input")
    local titlewidth = math.min(fn.strdisplaywidth(title), 12) + 2
    api.nvim_buf_set_extmark(titlebuf, ns, 0, 0, {
        virt_text = { { title, "Identifier" }, { ": ", "NonText" } },
        virt_text_win_col = 0
    })

    api.nvim_buf_set_name(buf, ("[Input: %s]"):format(title))
    local bo = vim.bo[buf]
    bo.filetype = "Input"
    bo.swapfile = false
    bo.bufhidden = "wipe"
    bo.omnifunc = input_omnifunc_decl
    cur_input_completion = opts.completion

    local columns = vim.o.columns
    ---@type vim.api.keyset.win_config
    local wincfg = {
        relative = "laststatus",
        anchor = "SW",
        zindex = 200, -- see https://github.com/neovim/neovim/discussions/32841#discussioncomment-12466448
        style = "minimal",
        border = "none",
        row = 2,
        col = 0,
        height = 1,
    }

    wincfg.width = titlewidth
    local titlewin = api.nvim_open_win(titlebuf, false, wincfg)

    wincfg.width = columns - titlewidth
    wincfg.col = titlewidth
    local win = api.nvim_open_win(buf, true, wincfg)

    if opts._ts_lang then
        vim.treesitter.start(buf, opts._ts_lang)
    end

    local augroup
    local clean = function()
        api.nvim_del_augroup_by_id(augroup)
        pcall(api.nvim_win_close, win, true)
        pcall(api.nvim_win_close, titlewin, true)
        if last_was_insert then
            vim.cmd.startinsert()
        else
            vim.cmd.stopinsert()
        end
    end
    local cancel = function()
        clean()
        callback(nil)
    end
    local confirm = function()
        local text = api.nvim_buf_get_lines(buf, 0, -1, false)[1]
        confirm_text(callback, text)
        clean()
    end

    augroup = utils.autogroup("config.ui.input.#" .. buf, {
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
    local map = utils.local_mapper(buf)

    map("n", "<esc>", cancel)
    map({ "i", "n" }, "<C-c>", cancel)

    map({ "i", "n" }, "<cr>", confirm)

    map({ "i", "s" }, "<Tab>", "<C-n>", { remap = true })

    map("n", "<localleader>q", cancel, { desc = "Input: Quit" })
    map("n", "<localleader>x", function()
        local text = api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        clean()
        expand_ui_input(callback, text, title, opts)
    end, { desc = "Input: Expand" })

    if not opts.default or opts.default:match("^%s*$") then
        vim.cmd("startinsert!")
    end
end
-- }}}

-- Popup Notifications {{{
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
-- }}}

return M
