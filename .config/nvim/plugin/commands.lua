--[[ Synopsis: Various utility commands {{{
  These are commands for a variety of things, including:
  - Zoxide integration
  - More intelligent window splitting
  - Tools for working with shell commands
  - Simple editing helpers
]]
local api = vim.api
local terminal = require("config.terminal")
local utils = require("config.utils")
local command = api.nvim_create_user_command
-- }}}

-- Zoxide {{{
local function get_zoxide_result(path)
    local expanded = path:gsub("~", vim.env.HOME)
    local cmd = { "zoxide", "query", expanded }
    local res = vim.system(cmd, {}):wait().stdout
    local dir = (res or ""):gsub("%s*$", "")
    if dir == "" or not dir then
        if vim.uv.fs_stat(path) then
            return path
        end
    end

    return dir
end

local function complete_zoxide(l, line, cpos)
    return vim.tbl_map(function(path)
        return path:gsub(vim.env["HOME"], "~")
    end, vim.split(vim.system({ "zoxide", "query", "-l", l }):wait().stdout, "\n"))
end

-- Use zoxide to edit a directory using oil
command("Zed", function(args)
    local name = args.fargs[1]
    local dir = get_zoxide_result(name)
    if not dir or dir == "" then
        utils.error("Zoxided", "Could not find " .. name)
        return
    end

    local mods = args.smods
    local cmd = mods.vertical and "vsplit" or (mods.horizontal and "split" or "edit")
    vim.cmd[cmd](dir)
end, {
    nargs = 1,
    complete = complete_zoxide,
    desc = "Use zoxide to open DIR in an oil buffer"
})

local zcd_func = function(args)
    local name = args.fargs[1]
    local dir = get_zoxide_result(name)
    if not dir or dir == "" then
        utils.error("Zoxide", "Could not find " .. name)
        return
    end

    vim.cmd.lcd(dir)
end
local zcd_args = {
    nargs = 1,
    complete = complete_zoxide,
    desc = ":lcd using zoxide"
}
command("Z", zcd_func, zcd_args)
command("Zcd", zcd_func, zcd_args)
-- }}}
-- Automatic Split {{{
---@param args vim.api.keyset.create_user_command.command_args
local function smart_split(args)
    local height = vim.api.nvim_win_get_height(0)
    local width = vim.api.nvim_win_get_width(0)

    local cmd
    if height * 2.6 > width then
        cmd = "split"
    else
        cmd = "vsplit"
    end

    local to_execute = ("%d%s %s"):format(
        math.floor((cmd == "split" and height or width) / 2),
        cmd,
        args.args
    )
    vim.cmd(to_execute)
end

---@type vim.api.keyset.user_command
local split_cmd_opts = {
    desc = "Split based on spiral layout",
    complete = "file",
    nargs = "?",
    count = 0,
    bar = true,
}

command("Sp", smart_split, split_cmd_opts)
command("Split", smart_split, split_cmd_opts)
-- }}}
-- Shell Utils {{{

-- Set qflist/loclist (with !bang) to result of command
-- Useful for e.g. ':Csh fd -e lua' or ':Csh git diff --name-only'
command("Csh", function(args)
    local cmd = args.fargs
    vim.system(cmd, {
        text = true
    }, vim.schedule_wrap(function(out)
        if out.code ~= 0 then
            utils.error("Csh",
                ("%s exited with code %d:\n%s"):format(args.args, out.code, out.stderr))
            return
        end

        -- `errorformat` is too complex for this, a simple list of names works just fine
        local items = vim.tbl_map(function(line)
            local path, rest = line:match("([^:]+):?(.*)")
            if not path or path == "" then
                return
            end
            local row, col, ctx
            if rest then
                row, col, ctx = rest:match("(%d+):(%d+):(.*)")
                row = row and tonumber(row)
                col = col and tonumber(col)
            end
            return { filename = path, lnum = row or 1, col = col or 1, text = ctx or "" }
        end, vim.split(out.stdout, "\n"))

        if args.bang then
            vim.fn.setloclist(0, items)
            vim.cmd.lwindow()
        else
            vim.fn.setqflist(items)
            vim.cmd.cwindow()
        end
    end))
end, {
    desc = "Populate qflist (or loclist with !) with shell command",
    complete = "shellcmd",
    nargs = "+",
    bang = true
})

---Run a single command in a floating window
command("Ft", function(args)
    terminal.open_term {
        position = "float",
        cmd = #args.fargs > 0 and args.fargs or nil,
        autoclose = args.bang,
    }
end, {
    desc = "Run shell command in floating terminal",
    complete = "shellcmd",
    nargs = "*",
    bang = true
})
-- }}}
-- LSP {{{
local lsp = vim.lsp
local lsp_complete_clients = function()
    return vim.tbl_map(function(client)
        return client.name
    end, lsp.get_clients { bufnr = 0 })
end

local iter_clients = function(buf, name)
    return ipairs(lsp.get_clients { bufnr = buf, name = name })
end

command("LspStop", function(args)
    local buf = api.nvim_get_current_buf()
    for _, client in iter_clients(buf, args.fargs[1]) do
        client:stop(args.bang)
    end
end, {
    desc = "Stop LSP servers",
    nargs = "*",
    bang = true,
    complete = lsp_complete_clients,
})

command("LspStart", function(args)
    lsp.start(lsp.config[args.args])
end, {
    desc = "Manually start LSP server",
    nargs = 1,
    complete = function()
        return vim.tbl_keys(lsp.get_configs())
    end
})

command("LspRestart", function(args)
    local detached = {}
    for _, client in iter_clients(api.nvim_get_current_buf(), args.fargs[1]) do
        if vim.tbl_count(client.attached_buffers) > 0 then
            detached[client.name] = { client, lsp.get_buffers_by_client_id(client.id) }
        end
        client:stop(args.bang)
    end
    local timer = assert(vim.uv.new_timer())
    timer:start(500, 100, vim.schedule_wrap(function()
        for name, info in pairs(detached) do
            ---@type vim.lsp.Client, integer[]
            local client, buffers = unpack(info)
            if client:is_stopped() then
                local new_id = assert(lsp.start(client.config, { attach = false }))
                for _, buf in pairs(buffers) do
                    lsp.buf_attach_client(buf, new_id)
                end
                detached[name] = nil
            end
        end

        if next(detached) == nil and not timer:is_closing() then
            timer:close()
        end
    end))
end, {
    desc = "Restart LSP servers",
    bang = true,
    nargs = "*",
    complete = lsp_complete_clients,
})

command("LspInfo", function(args)
    local buf = api.nvim_get_current_buf()
    for _, client in iter_clients(buf, args.fargs[1]) do
        local buffers = { table.concat(vim.tbl_keys(client.attached_buffers), ", "), "Number" }
        local cmd = { vim.inspect(client.config.cmd) }
        local rootdir = { client.root_dir or "nil", client.root_dir and "Directory" or "NonText" }

        local message = {
            { "\n" .. client.name, "Title" },
            { "\nBuffers: ",       "@property" }, buffers,
            { "\nCommand: ", "@property" }, cmd,
            { "\nRoot: ",    "@property" }, rootdir,
        }

        if client.server_info then
            vim.list_extend(message, {
                { "\nName: ",    "@property" }, { client.server_info.name, "Identifier" },
                { "\nVersion: ", "@property" }, { client.server_info.version, "SpecialChar" }
            })
        end

        if args.smods.verbose > 0 then
            vim.list_extend(message, {
                { "\nOptions\n",               "Title" },
                { vim.inspect(client.settings) },
            })
        end

        api.nvim_echo(message, false, {})
    end
end, {
    desc = "Show LSP servers",
    nargs = "*",
    complete = lsp_complete_clients
})
-- }}}
-- Editing {{{
local SHEBANG_NAMES = {
    awk = "/usr/bin/env -S awk -f",
    bash = "/usr/bin/env bash",
    lua = "/usr/bin/env luajit",
    python = "/usr/bin/env python",
    sh = "/bin/sh",
    zsh = "/usr/bin/env zsh",
}

command("Shebang", function(args)
    local ft = vim.bo.ft
    local shebang
    if args.fargs[1] then
        shebang = SHEBANG_NAMES[args.args] or ("/usr/bin/env " .. args.args)
        if not ft or ft == "" then
            vim.bo.ft = args.args
        end
    else
        if ft == "sh" and vim.b.is_bash then
            ft = "bash"
        end
        shebang = SHEBANG_NAMES[ft]
    end

    if not shebang then
        utils.error("Shebang", "No #! for " .. vim.bo.ft)
        return
    end

    -- if there is a shebang already, replace it
    if api.nvim_buf_get_lines(0, 0, 1, false)[1]:match("^#!.*") then
        api.nvim_buf_set_lines(0, 0, 1, false, { "#!" .. shebang })
    else
        api.nvim_buf_set_lines(0, 0, 0, false, { "#!" .. shebang, "" })
    end

    -- make the file executable when it's first written
    api.nvim_create_autocmd("BufWritePost", {
        command = "silent !chmod u+x %",
        buf = 0,
        once = true,
    })
end, {
    desc = "Add a shebang for the current buffer",
    nargs = "*",
    complete = function()
        return vim.tbl_keys(SHEBANG_NAMES)
    end
})

command("Number", function(args)
    local format = (args.args ~= "" and args.args or "%d ") .. "%s"

    local lines = api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
    local output = {}
    for i = 1, #lines do
        table.insert(output, format:format(i, lines[i]))
    end

    api.nvim_buf_set_lines(0, args.line1 - 1, args.line2, false, output)
end, {
    desc = "Number lines in range",
    range = true,
    nargs = "*",
})

---@type table<integer, integer>
local on_write_autocommands = {}
command("OnWrite", function(args)
    local buf = api.nvim_get_current_buf()
    if on_write_autocommands[buf] then
        api.nvim_del_autocmd(on_write_autocommands[buf])
    end

    local cmd = args.fargs
    local callback = function()
        if args.bang then
            local com = {}
            for _, item in ipairs(cmd) do
                table.insert(com, vim.fn.expand(item))
            end
            vim.system(
                { vim.o.shell, vim.o.shellcmdflag, table.concat(com, " ") },
                { text = true },
                function(out)
                    if out.code ~= 0 then
                        vim.schedule(function()
                            utils.error("OnWrite", out.stderr)
                        end)
                    end
                end)
            return
        else
            api.nvim_cmd({
                cmd = "!",
                args = cmd
            }, {})
        end
    end

    local id = api.nvim_create_autocmd("BufWritePost", {
        buf = buf,
        callback = callback
    })
    on_write_autocommands[buf] = id
end, {
    desc = "Run command on buffer save",
    nargs = "+",
    bang = true,
    complete = "shellcmd",
})

--[[ Save all of the specified options in a modeline at the start of the file (or the
  start if <bang> is given). Replaces an existing modeline if it can detect one
  (either at the start or end of the file) ]]
command("Modeline", function(args)
    local commentstring = vim.bo.commentstring
    if not commentstring or not commentstring:find("%%s") then
        utils.error("Modeline", "Cannot create modeline, 'commenstring' is not set")
        return
    end
    local escaped_commentstring = vim.pesc(commentstring)
    local modeline_pattern = escaped_commentstring:gsub("%%%%s", "vim: set .*")

    local set_cmd = {}
    for _, opt in ipairs(args.fargs) do
        local ok, val = pcall(api.nvim_get_option_value, opt, {})
        if not ok then
            utils.error("Modeline", val)
            return
        end
        local set
        if val == true then
            set = opt
        elseif val == false then
            set = "no" .. opt
        else
            set = ("%s=%s"):format(opt, val):gsub("[:%s]", "\\%1")
        end

        table.insert(set_cmd, set)
    end

    local directive = ("vim: set %s :"):format(table.concat(set_cmd, " "))
    local modeline = commentstring:format(directive)

    local linecount = api.nvim_buf_line_count(0)
    local firstline = api.nvim_buf_get_lines(0, 0, 1, false)[1]
    local lastline = api.nvim_buf_get_lines(0, linecount - 1, linecount, false)[1]

    local text = { modeline }
    local target, replace = 1, false
    if firstline:match(modeline_pattern) then
        target = 1
        replace = true
    elseif lastline:match(modeline_pattern) then
        target = linecount
        replace = true
    elseif args.bang then
        target = 0
        replace = false
        text = { modeline, "" }
    else
        target = linecount
        replace = false
        text = { "", modeline }
    end

    api.nvim_buf_set_lines(0, target - (replace and 1 or 0), target, false, text)
end, {
    desc = "Save options in modeline",
    nargs = "+",
    bang = true,
    complete = "option"
})

-- Collapse a sequence of non-initial whitespace into a single space
command("Squash", function(args)
    pcall(api.nvim_cmd, {
        cmd = "substitute",
        mods = { keeppatterns = true, },
        -- any whitespace preceded by non-whitespace, basically not at the ^BOL
        args = { [[/\S\zs\s\+/ /g]] },
        range = { args.line1, args.line2 }
    }, {})
end, {
    desc = "Squash multiple spaces into one",
    range = true,
})
-- }}}

command("Dash", function(args)
    require("config.dashboard").show()
end, { desc = "Open dashboard" })

command("Restart", function(args)
    local session = vim.fn.stdpath("state") .. "/restart.vim"
    vim.cmd.mksession { session, bang = true }
    vim.cmd.restart(("source %s"):format(session))
end, { desc = "Reload NeoVIM" })

command("Shuffle", function()
    local count = vim.fn.searchcount().total
    local tgt = vim.fn.rand() % count
    vim.cmd.normal { bang = true, ("gg%dn"):format(tgt) }
end, {
    desc = "Jump to a random search match"
})
