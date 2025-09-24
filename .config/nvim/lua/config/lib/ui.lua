local M = {}
local fn = vim.fn
local api = vim.api
local ns = api.nvim_create_namespace("config.ui")
M.ns = ns
local utils = require("config.utils")

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

return M
