---@type LazySpec
local M = {
    "cbochs/grapple.nvim"
}

--[[ Rationale {{{
Builtin neovim marks just don't cut it anymore
Grapple makes everything a *lot* nicer
}}} ]]

local on_window_open = function(window)
    local actions = require("grapple.tag_actions")
    local app = require("grapple").app()

    window:map("n", "<cr>", function()
        local cursor = window:cursor()
        window:perform_close(actions.select, { index = cursor[1] })
    end)
    window:map("n", "v", function()
        local cursor = window:cursor()
        window:perform_close(actions.select, { index = cursor[1], command = vim.cmd.vsplit })
    end)
    window:map("n", "s", function()
        local cursor = window:cursor()
        window:perform_close(actions.select, { index = cursor[1], command = vim.cmd.split })
    end)
    window:map("n", "t", function()
        local cursor = window:cursor()
        window:perform_close(actions.select, { index = cursor[1], command = vim.cmd.tabnew })
    end)

    window:map("n", "R", function()
        local entry = window:current_entry()
        local path = entry.data.path
        window:perform_retain(actions.rename, { path = path })
    end)

    window:map("n", "$", function()
        window:perform_close(actions.quickfix)
    end)

    for i, quick in ipairs(app.settings:quick_select()) do
        window:map("n", quick, function()
            window:perform_close(actions.select, { index = i })
        end)

        window:map("n", ("<M-%s>"):format(quick), function()
            window:perform_close(actions.select, { index = i, command = vim.cmd.Split })
        end)
    end
end

local colorized_display = function(entry, content)
    local path = require("grapple.path")

    local name = entry.tag.path
    local is_dir = vim.startswith(name, "oil://")
    if is_dir then
        name = name:gsub("^oil://", "")
    end

    local relative = path.relative(content.scope.path, name)
    if not relative then
        return
    end

    local tail, parent, hl
    if is_dir then
        tail = vim.fs.basename(relative) .. "/"
        parent = relative
        hl = "Directory"
    else
        tail = vim.fs.basename(relative)
        parent = vim.fs.dirname(relative)
        hl = require("config.utils").highlight_fname(name)
    end

    local marks = {}

    local virt_text = {
        { parent, "NonText" },
    }

    table.insert(marks, {
        hl_group = hl,
        end_col = vim.fn.strdisplaywidth(tail) + 5,
        virt_text = virt_text,
        virt_text_pos = "eol_right_align",
    })

    return {
        display = tail,
        marks = marks
    }
end

---@type grapple.settings
local opts = {
    scope = "lsp",
    icons = false,
    win_opts = {
        width = 48,
        height = 20,
        row = 0.5,
        col = 0.5,

        border = "rounded",
        relative = "editor",
        footer = "",
    },
    tag_hook = on_window_open,
    -- allow for more at once
    quick_select = "1234567890,.!@#$%^&*",
    style = "colorized",
    styles = {
        colorized = colorized_display,
    }
}

M.config = function()
    local grapple = require("grapple")

    grapple.setup(opts)

    local utils = require("config.utils")
    local map = utils.map

    local add_grapple = function()
        if vim.v.count > 0 then
            grapple.tag { index = vim.v.count }
        else
            grapple.tag()
        end
    end

    local rm_grapple = function()
        if vim.v.count > 0 then
            grapple.untag { index = vim.v.count }
        else
            grapple.untag()
        end
    end

    map("n", "<C-t>", add_grapple)
    map("n", "<space>+g", add_grapple)
    map("n", "<space>-g", rm_grapple)

    -- use the same prefix as the buffer maps
    map("n", "'g", function() grapple.open_tags() end)
    map("n", "'G", function() grapple.open_scopes { all = true } end)

    -- the file position is obvious anyways
    map("n", '<C-g>', function()
        if vim.v.count == 0 then
            grapple.open_tags()
        else
            grapple.select { index = vim.v.count }
        end
    end)
    -- split
    map("n", '<M-C-g>', function()
        if vim.v.count == 0 then
            grapple.open_tags()
        else
            grapple.select { index = vim.v.count, command = vim.cmd.Split }
        end
    end)
end

return M
