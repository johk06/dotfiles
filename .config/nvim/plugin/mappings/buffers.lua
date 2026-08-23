--[[ Synopsis: Buffer Management and Window navigation {{{
 Mappings use the ' prefix
 there still is ` for marks, ' is on the home row, soooo nice
 This prefix is also used in other places whenever a buffer needs to be managed
]]

local api = vim.api
local fn = vim.fn
local utils = require("config.utils")
local map = utils.map

local leader = "'"
-- Make sure that it waits for input
map("n", leader, "<nop>")
map("n", "<M-'>", "`") -- But at the same time, keep it if ever needed
-- }}}

-- This is the norm for lots of plugin's floating windows already, avoid surprises
-- See mappings/register.lua for my replacement for the old q
map("n", "q", function()
    local ok = pcall(vim.cmd.close)
    if not ok then
        vim.cmd.bnext()
    end
end)

-- Linear Movements {{{
map("n", leader .. "j", "<cmd>bnext<cr>", { desc = "Buffer: Next" })
map("n", leader .. "k", "<cmd>bprev<cr>", { desc = "Buffer: Prev" })

map("n", leader .. "J", "gt", { desc = "Tab: Next" })
map("n", leader .. "K", "gT", { desc = "Tab: Prev" })
-- }}}
--[[ Indexed Operations {{{
 These use the indices from plugin/bufferline.lua, specified as v:count
]]

local function get_buf_idx()
    local target
    local count = vim.v.count
    if count == 0 then
        target = api.nvim_get_current_buf()
    else
        target = Bufs_for_idx[count]
    end
    if not target or not api.nvim_buf_is_valid(target) then
        utils.error("Mappings", "No Buffer #" .. count)
        return
    end

    return target
end

-- Go to the buffer
local goto_buf = function()
    if vim.v.count == 0 then
        vim.cmd.bnext()
        return
    end

    local target = get_buf_idx()
    if not target then return end

    local win = fn.bufwinid(target)
    if win > 0 then
        api.nvim_set_current_win(win)
        return
    end

    local ok = pcall(api.nvim_set_current_buf, target)
    if not ok then
        vim.cmd.bprevious()
    end
end

map("n", leader .. leader, goto_buf, { desc = "Buffer: Show" })

-- Easier to type alternate file, mnemonic: [s]econd or [s]witch, also allows remapping <C-6>
map("n", "<C-s>", function()
    if vim.v.count == 0 then
        local alt = fn.bufnr("#")
        local w = fn.bufwinid(alt)

        if w ~= -1 then
            api.nvim_set_current_win(w)
        else
            api.nvim_set_current_buf(alt)
        end
    else
        goto_buf()
    end
end)

---@param dir config.win.position
---@param opts config.win.opts?
local function open_buf_in(dir, opts)
    return function()
        local target = get_buf_idx()
        if not target then return end

        utils.win_show_buf(target, vim.tbl_extend("force", { position = dir }, opts or {}))
    end
end

-- 'v, 's are equivalent to <C-w>v and <C-w>s, just with v:count specifying something other than the width
map("n", leader .. "v", open_buf_in("vertical"), { desc = "Buffer: Show vsplit" })
map("n", leader .. "s", open_buf_in("horizontal"), { desc = "Buffer: Show split" })
map("n", leader .. "V", open_buf_in("vertical", { direction = "left" }), { desc = "Buffer: Show vsplit (before)" })
map("n", leader .. "S", open_buf_in("horizontal", { direction = "above" }), { desc = "Buffer: Show split (before)" })
map("n", leader .. "t", open_buf_in("tab"), { desc = "Buffer: Show tab" })
map("n", leader .. "f", open_buf_in("float"), { desc = "Buffer: Show float" })
map("n", leader .. "a", open_buf_in("autosplit"), { desc = "Buffer: Show auto" })
map("n", leader .. "r", open_buf_in("replace"), { desc = "Buffer: Replace current" })
map("n", leader .. "p", function()
    local buf = get_buf_idx()
    if not buf then return end
    vim.cmd(("%dpb"):format(buf))
end, { desc = "Buffer: Show Preview" })
-- }}}
-- Closing {{{
map("n", leader .. "P", "<cmd>pclose<cr>", { desc = "Buffer: Close Preview" })

local delete_buffer = function(buf)
    local ok = pcall(api.nvim_buf_delete, buf, {})
    if not ok then
        local short = Short_for_bufs[buf]
        local name = utils.format_buf_name(buf) or "[-]"
        local msg = ("Buffer %s%d (%s) is modified, force delete? [y/N] "):format(short and "#" or ".", short, name)
        local response = vim.fn.input { prompt = msg }
        if response:lower() == "y" then
            api.nvim_buf_delete(buf, { force = true })
        end
    end
end

-- Delete
map("n", leader .. "d", function()
    local target = get_buf_idx()
    if not target then return end

    delete_buffer(target)
end, { desc = "Buffer: Delete" })

-- Hide - Close the first window that the buffer is shown in
map("n", leader .. "h", function()
    local target = get_buf_idx()
    if not target then return end

    local win = fn.bufwinid(target)
    if win == -1 then
        utils.error("Mappings", "No open Window for Buffer ")
        return
    end
    api.nvim_win_close(win, false)
end, { desc = "Buffer: Hide win" })

---@param cb fun(bufnr: integer)
local on_hidden = function(cb, preserve_alt)
    local alt = vim.fn.bufnr("#")
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if (not preserve_alt or buf ~= alt)
            and vim.bo[buf].buflisted and fn.bufwinid(buf) == -1 then
            cb(buf)
        end
    end
end

-- Clear hidden buffers
map("n", leader .. "c", function()
    on_hidden(delete_buffer, true)
end, { desc = "Buffer: Clear Hidden" })
map("n", leader .. "C", function()
    on_hidden(delete_buffer, false)
end, { desc = "Buffer: Clear Hidden" })
-- }}}
--[[ Tabs {{{
 Roughly the same situation
 I do not use tabs much, hence the capital letters
]]

-- Run cmd with the effective tab target as an argument
local function indexed_tab_command(cmd)
    local target
    local count = vim.v.count
    if count == 0 then
        target = ""
    else
        target = Tabs_for_idx[count]
    end

    utils.run_excmd(cmd, { target })
end

local function get_tab_idx()
    local target
    local count = vim.v.count
    if count == 0 then
        target = api.nvim_get_current_tabpage()
    else
        target = Tabs_for_idx[count]
    end
    if not target or not api.nvim_tabpage_is_valid(target) then
        utils.error("Mappings", "No Tab #" .. count)
        return
    end

    return target
end

-- Close a tab without disturbing the windows
map("n", leader .. "H", function() indexed_tab_command("tabclose") end, { desc = "Tab: Hide" })

--[[ Fully delete all of a tab's buffers
 Useful for things like <space>g<C-h> from plugins/git.lua ]]
map("n", leader .. "D", function()
    local tab = get_tab_idx()
    if not tab then
        return
    end

    local seen = {}
    local bufs = vim.tbl_filter(function(buf)
        local keep = not seen[buf]
        seen[buf] = true
        return keep and api.nvim_buf_is_valid(buf)
    end, vim.tbl_map(function(win)
        return api.nvim_win_get_buf(win)
    end, api.nvim_tabpage_list_wins(tab)))

    for _, buf in ipairs(bufs) do
        delete_buffer(buf)
    end
end, { desc = "Tab: Delete recursively" })
-- }}}
-- Terminal Windows {{{
local terminal = require("config.terminal")

local termleader = "<space>t"
map("n", termleader .. "s", function() terminal.open_term { position = "horizontal" } end)
map("n", termleader .. "v", function() terminal.open_term { position = "vertical" } end)
map("n", termleader .. "r", function() terminal.open_term { position = "replace" } end)
map("n", termleader .. "f", function() terminal.open_term { position = "float" } end)
map("n", termleader .. "a", function() terminal.open_term { position = "autosplit" } end)
map("n", termleader .. "t", function() terminal.open_term { position = "autosplit" } end)

-- lf integrates nicely by calling nvr when it needs to open stuff
map("n", termleader .. "l", function()
    terminal.open_term {
        position = "autosplit",
        cmd = { "lf" }
    }
end)

-- various other useful programs
map("n", termleader .. "p", function()
    terminal.open_term {
        position = "autosplit",
        cmd = { "python" },
        title = "python"
    }
end)
map("n", termleader .. "q", function()
    terminal.open_term {
        position = "autosplit",
        cmd = { "qalc" },
        title = "qalc",
        size = { 60, 20 },
    }
end)
-- }}}
