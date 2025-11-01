local M = {}
local api = vim.api
local fn = vim.fn
local utils = require("config.utils")

M.last_term = 0

-- remove the builtin handler
utils.del_autocommand("nvim.terminal", "TermClose")

---@param buf integer
---@param fun fun(res: {pos: [integer, integer], url: TermUrl})
local function operate_on_urls(buf, fun)
    local info = fn.getwininfo(api.nvim_get_current_win())[1]
    local first = info.topline
    local last = info.botline

    local targets = {}
    for _, url in ipairs(M.urls_for_buffers[buf]) do
        if url[1] >= first then
            table.insert(targets, {
                pos = { url[1], url[2] + 1 },
                url = url
            })
        elseif url[1] > last then
            break
        end
    end
    require("leap").leap {
        targets = targets,
        action = fun
    }
end

---@type table<string, fun(ev: vim.api.keyset.create_autocmd.callback_args)>
local osc_handlers = {}

-- OSC 8, operate on URIs {{{
---@alias TermUrl [integer, integer, integer, integer, string]
---@type table<integer, TermUrl[]>
M.urls_for_buffers = {}

local last_osc8_start
local last_osc8_path
local hostname = fn.hostname()

osc_handlers["8"] = function(ev)
    ---@type [integer, integer]
    local cursor = ev.data.cursor

    if not M.urls_for_buffers[ev.buf] then
        M.urls_for_buffers[ev.buf] = {}
    end
    if last_osc8_start then
        table.insert(M.urls_for_buffers[ev.buf], {
            last_osc8_start[1],
            last_osc8_start[2],
            cursor[1],
            cursor[2],
            last_osc8_path,
        })
        last_osc8_start = nil
        return
    end

    local uri = ev.data.sequence:gsub("^\x1b]8;.-;", "")
    if vim.startswith(uri, "file://") then
        local host = uri:match("^file://(.-)/")
        if host and host ~= "" then
            if host == hostname then
                last_osc8_path = vim.uri_to_fname(uri:gsub("^file://.-/", "file:///"))
            end
        else
            last_osc8_path = vim.uri_to_fname(uri)
        end
        last_osc8_start = cursor
    end
end
-- }}}

-- OSC 133, Capture command output {{{
---@alias TermCommandOutput [integer, integer]
---@type table<integer, TermCommandOutput>
M.command_output_for_buffers = {}

local last_osc133_start

osc_handlers["133"] = function(ev)
    local cursor = ev.data.cursor
    local code = ev.data.sequence:sub(7)
    ---@type "A"|"B"|"C"|"D"
    local subtype = code:sub(1, 1)
    if subtype == "C" then
        last_osc133_start = cursor[1]
    elseif subtype == "D" then
        if last_osc133_start then
            table.insert(M.command_output_for_buffers[ev.buf], {
                last_osc133_start,
                cursor[1],
            })
            last_osc133_start = nil
        end
    end
end
-- }}}

---@param ev vim.api.keyset.create_autocmd.callback_args
local set_is_interactive = function(ev)
    local pid = ev.file:match("term://.-//(%d+):")
    if pid then
        vim.uv.fs_open(("/proc/%d/cmdline"):format(pid), "r", 0, function(err, fd)
            if err then
                return
            end

            local cmdline, err = vim.uv.fs_read(fd, 4096, 0)
            vim.uv.fs_close(fd)
            if not cmdline or err then
                return
            end

            -- automatically close interactive git add buffers
            if cmdline:match("git\0.-add\0%-p") then
                vim.schedule(function()
                    vim.b[ev.buf].term_autoclose = true
                end)
            end
        end)
    end
end

utils.autogroup("config.terminal_mode", {
    -- saner options
    TermOpen = function(ev)
        set_is_interactive(ev)
        vim.wo[0][0].number = false
        vim.wo[0][0].relativenumber = false
        vim.wo[0][0].statuscolumn = ""
        vim.wo[0][0].signcolumn = "no"
        -- immediately hand over control
        vim.cmd.startinsert()

        M.urls_for_buffers[ev.buf] = {}
        M.command_output_for_buffers[ev.buf] = {}

        local map = utils.local_mapper(ev.buf)

        local split_path = function()
            operate_on_urls(ev.buf, function(res)
                vim.cmd.Split(res.url[5])
            end)
        end

        map("n", "<localleader>f", split_path)
        map("n", "gf", function()
            local osc8_files = M.urls_for_buffers[ev.buf]
            local cursor = api.nvim_win_get_cursor(0)
            for _, file in ipairs(osc8_files) do
                if file[1] <= cursor[1] and file[3] >= cursor[2] and file[2] <= cursor[2] and file[4] >= cursor[2] then
                    vim.cmd.edit(file[5])
                    return
                end
            end
            vim.cmd.normal { bang = true, "gf" }
        end)
        map("t", "<M-p>", split_path)
        map("t", "<M-i>", function()
            operate_on_urls(ev.buf, function(res)
                vim.api.nvim_paste(fn.shellescape(res.url[5]), false, -1)
            end)
        end)
    end,

    -- automatically close interactive term buffers
    TermClose = {
        nested = true, -- trigger BufDelete
        callback = function(ev)
            if vim.v.event.status ~= 0 then
                return
            end

            if vim.b[ev.buf].term_autoclose == true then
                api.nvim_win_close(0, true)
                api.nvim_buf_delete(ev.buf, { force = true })
            end

            M.urls_for_buffers[ev.buf] = nil
            M.command_output_for_buffers[ev.buf] = nil
        end
    },

    -- automatically enter insert
    [{ "BufWinEnter", "WinEnter" }] = function(ev)
        -- make sure that remote leap operations are not affected
        if vim.bo[ev.buf].buftype == "terminal" then
            vim.cmd.startinsert()
            M.last_term = ev.buf
        end
    end,

    -- Handle OSC sequences
    TermRequest = function(ev)
        ---@type string
        local escape = ev.data.sequence
        if escape:sub(1, 2) ~= "\x1b]" then
            return
        end

        local code = escape:match("^\x1b](.-);")
        local handler = osc_handlers[code]
        if handler then
            handler(ev)
        end
    end
})

local function get_cmd_and_cwd(bufname, opts)
    local cmd = {}
    local cwd = ""
    local final_cmd = false

    if vim.startswith(bufname, "oil-ssh://") then
        final_cmd = true
        local addr, remote_path = bufname:match("//(.-)(/.*)")
        vim.list_extend(cmd, { "ssh", "-t", addr, "--", "cd", remote_path:sub(2, -1), ";", "exec", "${SHELL:-/bin/sh}" })
    elseif vim.startswith(bufname, "oil://") then
        cwd = assert(require("oil").get_current_dir())
    elseif opts.cwd then
        cwd = opts.cwd
    else
        cwd = fn.fnamemodify(bufname, ":p:h")
        if not vim.uv.fs_stat(cwd) then
            cwd = fn.getcwd()
        end
    end

    if not final_cmd then
        if opts.cmd then
            vim.list_extend(cmd, opts.cmd)
        else
            vim.list_extend(cmd, { vim.o.shell })
        end
    end

    return cmd, cwd
end

---@param opts {position: config.win.position, cmd: string[]|nil, cwd: string|nil, title: string|nil, size: [number, number], autoclose: boolean?}
function M.open_term(opts)
    local curbuf = api.nvim_get_current_buf()
    local bname = api.nvim_buf_get_name(curbuf)
    local cmd, cwd = get_cmd_and_cwd(bname, opts)

    local b = api.nvim_create_buf(true, false)
    vim.b[b].term_autoclose = opts.autoclose == nil and true or opts.autoclose

    utils.win_show_buf(b, { position = opts.position, size = opts.size })

    fn.jobstart(cmd, {
        cwd = cwd,
        term = true,
    })

    M.last_term = b
    vim.b[curbuf].terminal_buffer = b

    if opts.title then
        vim.b[0].term_title = opts.title
    end
end

return M
