--[[ LSP-Configuration
Utilities and mappings for LSPs
]]

local M = {}

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local ui = require("config.lib.ui")
local lsp = vim.lsp

-- Mappings {{{
---@type [nvim_mode, string, function|string, vim.keymap.set.Opts?][]
local lsp_mappings = {
    {
        utils.mode_action, "<space>a",
        lsp.buf.code_action,
        { desc = "LSP: Code action" }
    },

    -- renaming: two ways
    -- the classic way that uses vim.ui.input, useful if more than one edit needs to be made
    {
        "n", "<space>r",
        lsp.buf.rename,
        { desc = "LSP: Rename symbol" }
    },

    {
        "n", "glc",
        function() lsp.buf.incoming_calls() end,
        { desc = "LSP: List Callers" }
    },
    {
        "n", "glC",
        function() lsp.buf.outgoing_calls() end,
        { desc = "LSP: List Called Functions" }
    },

    {
        "n", "<C-w>u",
        function() lsp.buf.signature_help() end,
        { desc = "LSP: Usage Info" }
    }
}

---@param abbrev string
---@param cb function
---@param desc string
local do_map_list = function(abbrev, cb, desc)
    table.insert(lsp_mappings, {
        "n", "<C-w>g" .. abbrev,
        function()
            utils.open_window_smart(0, { enter = true })
            cb { reuse_win = false, loclist = true }
            vim.cmd.normal("zz")
        end,
        { desc = ("LSP: (other Window) %s"):format(desc) }
    })
    table.insert(lsp_mappings, {
        "n", "<C-w><C-g>" .. abbrev,
        function()
            vim.cmd("botright pedit %")

            local old_win = api.nvim_get_current_win()
            local cur = api.nvim_win_get_cursor(old_win)
            local pv_win = vim.iter(api.nvim_list_wins()):find(function(w)
                return vim.wo[w].previewwindow
            end)

            vim.wo[pv_win].scrolloff = 0
            vim.wo[pv_win].cursorlineopt = "line"
            api.nvim_win_call(pv_win, function()
                api.nvim_win_set_cursor(pv_win, cur)
                vim.cmd.normal("zt")
                cb { reuse_win = false, loclist = true }
                vim.cmd.normal("zt")
            end)
        end,
        { desc = ("LSP: (other Window) %s"):format(desc) }
    })

    table.insert(lsp_mappings, {
        "n", "gl" .. abbrev,
        function() cb { loclist = true } end,
        { desc = ("LSP: List %s (local)"):format(desc) }
    })

    table.insert(lsp_mappings, {
        "n", "gl" .. abbrev:upper(),
        function() cb() end,
        { desc = ("LSP: List %s (qflist)"):format(desc) }
    })
end

do_map_list("d", lsp.buf.definition, "Definitions")
do_map_list("r", function(params)
    lsp.buf.references(nil, params)
end, "References")
do_map_list("i", lsp.buf.implementation, "Implementations")

---@param abbrev string
---@param kinds string[]
---@param desc string
local map_list_symbol_kind = function(abbrev, kinds, desc)
    local filter = function(t)
        return vim.tbl_contains(kinds, t.kind)
    end
    table.insert(lsp_mappings, {
        "n", "gl" .. abbrev,
        function()
            lsp.buf.document_symbol { on_list = function(ts)
                local items = vim.tbl_filter(filter, ts.items)
                vim.fn.setloclist(0, items)
                if #items > 0 then
                    vim.cmd.lopen()
                end
            end }
        end,
        { desc = ("LSP: List %s (local)"):format(desc) }
    })
    table.insert(lsp_mappings, {
        "n", "gl" .. abbrev:upper(),
        function()
            lsp.buf.workspace_symbol("", {
                on_list = function(ts)
                    local items = vim.tbl_filter(filter, ts.items)
                    vim.fn.setqflist(items)
                    if #items > 0 then
                        vim.cmd.copen()
                    end
                end
            })
        end,
        { desc = ("LSP: List %s (global)"):format(desc) }
    })
end

map_list_symbol_kind("f", { "Function" }, "Functions")
map_list_symbol_kind("k", { "Class", "Struct", "Enum", "Interface" }, "Type (kinds)")


---Add a mapping for when LSP is active
---@param mode nvim_mode
---@param keys string
---@param action string|function
---@param opts vim.keymap.set.Opts?
M.lsp_map = function(mode, keys, action, opts)
    table.insert(lsp_mappings, { mode, keys, action, opts })
end
-- }}}
-- Commands {{{
---@param args vim.api.keyset.create_user_command.command_args
local inlay_hint_command = function(args)
    local cmd = args.fargs[1]
    if cmd then
        if cmd == "on" then
            lsp.inlay_hint.enable(true)
        elseif cmd == "off" then
            lsp.inlay_hint.enable(false)
        end
    else
        lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled())
    end
end

---@param args vim.api.keyset.create_user_command.command_args
local sdo_command = function(args)
    lsp.buf.references(nil, {
        on_list = function(res)
            for _, elem in ipairs(res.items) do
                local buf = fn.bufadd(elem.filename)
                fn.bufload(buf)
                api.nvim_buf_call(buf, function()
                    api.nvim_win_set_cursor(0, { elem.lnum, elem.col - 1 })
                    vim.cmd(args.args)
                end)
                if vim.bo[buf].modified then
                    vim.bo[buf].buflisted = true
                end
            end
        end
    })
end

---@type table<string, [fun(args: vim.api.keyset.create_user_command.command_args), vim.api.keyset.user_command]>
local lsp_commands = {
    InlayHint = {
        inlay_hint_command,
        {
            nargs = "?",
            desc = "LSP: Set Inlay-Hints",
            complete = function()
                return { "on", "off" }
            end
        }
    },
    Sdo = {
        sdo_command,
        {
            desc = "LSP: Execute CMD for every occurence of the symbol",
            complete = "command",
            nargs = "+",
        }
    }
}

-- }}}
-- Callbacks {{{
local on_lsp_attached = function(ev)
    local buf = ev.buf

    local map = utils.local_mapper(buf, { group = true })
    for _, action in ipairs(lsp_mappings) do
        map(action[1], action[2], action[3], action[4])
    end

    local client = lsp.get_client_by_id(ev.data.client_id) --[[@as vim.lsp.Client]]

    -- make the 'path' match the one of the language server
    -- NOTE: don't replace the whole 'path', since that might be set by ftplugins
    if client and client.workspace_folders then
        local workspace_path = vim.tbl_map(function(t)
            return vim.uri_to_fname(t.uri) .. "/**"
        end, client.workspace_folders)

        vim.opt_local.path:prepend(workspace_path)
        -- remove all the basic wildcards
        vim.opt_local.path:remove { "*", "../*" }

        local folder = vim.uri_to_fname(client.workspace_folders[1].uri)
        -- that's basically always wrong
        if folder ~= vim.env.HOME then
            fn.chdir(folder)
        end
    end

    for cmd, action in pairs(lsp_commands) do
        api.nvim_buf_create_user_command(buf, cmd, action[1], action[2])
    end

    require("workspace-diagnostics").populate_workspace_diagnostics(client, buf)
end

local on_lsp_detached = function(ev)
    -- reset the 'path'
    vim.opt_local.path = vim.opt_global.path

    pcall(utils.unmap_group, ev.buf)
    for cmd, _ in pairs(lsp_commands) do
        pcall(api.nvim_buf_del_user_command, ev.buf, cmd)
    end
end

local lsp_status_notif = ui.floating_notif_new {
    align = "right",
    max_width = 40,
    name = "LSP"
}

---@param ev vim.api.keyset.create_autocmd.callback_args
local on_lsp_progress = function(ev)
    local data = ev.data
    local client = lsp.get_client_by_id(data.client_id)
    if not client then
        return
    end

    local value = data.params.value

    local message = {
        { client.name, "Identifier" },
        { ": ",        "Delimiter" },
    }

    if value.kind == "end" then
        table.insert(message, { "Finished " })
        table.insert(message, { value.title })
        vim.defer_fn(function()
            ui.floating_notif_hide(lsp_status_notif)
        end, 1000)
    elseif value.percentage then
        table.insert(message, { value.title })
        table.insert(message, { (" %02d%%"):format(value.percentage), "Number" })
    end

    ui.floating_notif_put(lsp_status_notif, message)
end

utils.autogroup("config.lsp", {
    LspAttach = on_lsp_attached,
    LspDetach = on_lsp_detached,
    LspProgress = on_lsp_progress,
})
-- }}}

---@param client vim.lsp.Client
---@param category string
---@param v any
M.add_setting = function(client, category, v)
    if not client.settings then
        client.settings = {}
    end
    if not client.settings[category] then
        client.settings[category] = {}
    end

    client.settings[category] = vim.tbl_extend("force", client.settings[category] --[[@as table]], v)
end

-- load schemastore on launch only
---@param type "json"|"yaml"
M.lazy_schemastore = function(type)
    ---@param client vim.lsp.Client
    return function(client)
        ---@diagnostic disable-next-line: undefined-field
        M.add_setting(client, "json", { schemas = require("schemastore")[type].schemas() })
    end
end

-- Enable all configured servers
local servers = {}
for _, file in ipairs(api.nvim_get_runtime_file("lsp/*.lua", true)) do
    local server = fn.fnamemodify(file, ":t:r")
    table.insert(servers, server)
end

-- Schedule to avoid recursive requires
vim.schedule(function()
    vim.lsp.enable(servers)
end)


return M
