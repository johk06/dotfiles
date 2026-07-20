-- incredibly simply typst preview
local M = {}

local lsp = vim.lsp
local api = vim.api
local utils = require("config.utils")

local id_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
local rand_id = function(len)
    local id = require("string.buffer").new(len)
    for i = 1, len do
        local idx = math.random(i, #id_chars)
        id:put(id_chars:sub(idx, idx))
    end
    return tostring(id)
end
local get_buf_path = function(buf)
    return vim.fs.abspath(api.nvim_buf_get_name(buf))
end

---@param client vim.lsp.Client
---@param cmd string
---@param args any
---@param cb fun(err: string?, res)?
local exec_cmd = function(client, cmd, args, cb)
    local status, id = client:request("workspace/executeCommand", {
            command = cmd,
            arguments = args,
        },
        ---@type lsp.Handler
        function(err, res, ctx)
            if cb then
                cb(err and err.message or nil, res)
            end
        end
    )
end

local if_addr_not_in_use = function(addr, port, cb)
    local tcp = vim.uv.new_tcp()
    tcp:connect(addr, port, function(err)
        if err then
            vim.schedule(cb)
        end
    end)
end

local get_tinymist = function(buf)
    local client = lsp.get_clients({ name = "tinymist", bufnr = buf })[1]
    if not client then
        utils.error("Typst", "No tinymist attached to buffer")
        return nil
    end
    return client
end

M.previews = {}
local find_preview = function(client, buf)
    if not M.previews[client] then
        return nil
    end

    local tasks = M.previews[client]
    if tasks[buf] then return tasks[buf] end

    local _, task = next(tasks)
    return task
end

local host = "127.0.0.1"
local default_port = 8000

local scroll_preview = function(client, task)
    local path = get_buf_path(0)
    local cursor = api.nvim_win_get_cursor(0)
    exec_cmd(client, "tinymist.scrollPreview", {
        task,
        {
            event = "panelScrollTo",
            filepath = path,
            line = cursor[1],
            character = cursor[2] + 1
        }
    })
end

---@param buf integer
---@param opts {port: integer?}
---@param cb function?
M.attach = function(buf, opts, cb)
    buf = buf or 0
    local client = get_tinymist(buf)
    if not client then
        return
    end
    opts = opts or {}
    local port = opts.port or default_port
    if_addr_not_in_use(host, port, function()
        local task = rand_id(12)
        local args = {
            "--no-open",
            "--task-id", task,
            "--data-plane-host",
            host .. ":" .. port,
            get_buf_path(buf)
        }

        exec_cmd(client, "tinymist.doStartPreview", { args }, function(err, res)
            if err ~= nil then
                utils.error("Typst", err)
                return
            end

            M.previews[client] = M.previews[client] or {}
            M.previews[client][buf] = {
                task = task,
                augroup = utils.autogroup("typst-preview." .. task, {
                    CursorMoved = function(ev)
                        if client.attached_buffers[ev.buf] then
                            scroll_preview(client, task)
                        end
                    end
                })
            }

            if cb then
                vim.schedule(function()
                    cb(port, client)
                end)
            end
        end)
    end)
end

M.open = function(port)
    vim.system({ "launch-or-inside", "firefox", "firefox", "--new-window", ("http://%s:%d"):format(host,
        port or default_port) })
end

M.start = function(buf, opts)
    M.attach(buf or 0, opts, M.open)
end

local exec_with = function(buf, fn)
    local client = get_tinymist(buf)
    if not client then
        return
    end
    local task = find_preview(client, buf)
    if not task then
        return
    end
    fn(client, buf, task)
end
---@param fn fun(client: vim.lsp.Client, buf: integer, preview: table)
local action = function(fn)
    return function(buf)
        exec_with(buf, fn)
    end
end
M.close = action(function(client, buf, preview)
    exec_cmd(client, "tinymist.doKillPreview", { preview.task })
end)

return M
