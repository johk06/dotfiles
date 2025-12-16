--[[ Rationale
Oil allows edits to the file system to work the same as text files
Additionally, it's really fast and rock solid
Extensibility is pretty good too
]]

---@type LazySpec
local M = {
    "stevearc/oil.nvim",
}
local utils = require("config.utils")

-- Columns {{{
local perms_hlgroups = {
    ["-"] = "OilNoPerm",
    ["r"] = "OilRead",
    ["w"] = "OilWrite",
    ["x"] = "OilExec",
    ["T"] = "OilSticky",
    ["t"] = "OilSticky",
    ["s"] = "OilSetuid",
}

local oil_columns = {
    permissions = {
        "permissions",
        highlight = function(str)
            local hls = {}
            for i = 1, #str do
                table.insert(hls, { perms_hlgroups[str:sub(i, i)], i - 1, i })
            end
            return hls
        end,
    },
    time = {
        "smart_mtime",
    },
    birthtime = {
        "smart_btime",
    },
    size = {
        "size",
        highlight = function(str)
            local suffixes = {
                k = 1024,
                M = 1048576,
                G = 1073741824,
            }
            local factor = suffixes[str:sub(-1, -1)] or 1
            local size = factor * tonumber(str:match("^%d+"))
            return utils.highlight_size(size)
        end
    },
}

local column_positions = {
    birthtime = 1,
    time = 2,
    size = 3,
    group = 4,
    user = 5,
    permissions = 6,
}

local enabled_columns = {
    nil,
    "time",
    nil,
    nil,
    "user",
    "permissions"
}
-- }}}

-- Custom actions essentially {{{
local function get_entries()
    local oil = require("oil")

    local ret = {}
    local startl, endl = utils.get_cur_line_range()
    for i = startl, endl do
        local e = oil.get_entry_on_line(0, i)
        if e then
            table.insert(ret, e)
        end
    end

    return ret
end

local function open_cmd(cmd)
    local files = vim.tbl_map(function(e)
        return vim.fn.fnameescape(e.name)
    end, get_entries())

    vim.api.nvim_feedkeys(":", "n")
    vim.schedule(function()
        vim.fn.setcmdline(cmd .. " " .. table.concat(files, " "), #cmd + 1)
    end)
end

local function goto_git_ancestor()
    local path = require("oil").get_current_dir()
    if not path then
        return
    end

    local git_ancestor = vim.fs.root(path, ".git")

    if not git_ancestor then
        utils.warn("Oil", "Not in a git repo")
        return
    end

    -- avoid flicker
    if git_ancestor == path or git_ancestor .. "/" == path then
        return
    end

    require("oil").open(git_ancestor)
end

local sort = {
    { "type", "asc" },
    { "name", "asc" },
}

local sort_types = {
    size = {
        { "size", "desc" },
        { "name", "asc" }
    },
    time = {
        { "smart_btime", "desc" },
        { "name",        "asc" }
    },
    default = {
        { "type", "asc" },
        { "name", "asc" }
    }
}

local function set_sort(action)
    if action == "invert" then
        sort[1][2] = (sort[1][2] == "asc" and "desc" or "asc")
    else
        sort = sort_types[action]
    end

    require("oil").set_sort(sort)
end

local function toggle_column(col)
    local pos = column_positions[col]
    if enabled_columns[pos] then
        enabled_columns[pos] = nil
    else
        enabled_columns[pos] = col
    end
    require("oil").set_columns(vim.tbl_map(function(c)
        return oil_columns[c] or c
    end, vim.tbl_values(enabled_columns)))
end

local function default_is_hidden(name, bufnr)
    if name then
        return name:sub(1, 1) == "."
    else
        return false
    end
end

local cur_filter_pattern

local function filter_items()
    local function set_filter(filter)
        require("oil").set_is_hidden_file(function(fname, buf)
            -- HACK: prevent dir from being empty
            if fname == ".." then
                return false
            end

            return vim.regex(filter):match_str(fname) == nil
        end)
    end
    vim.ui.input({
        default = cur_filter_pattern,
        prompt = "Filter Regex",
        _ts_lang = "regex",
        -- abuse it to update continuously
        highlight = function(pattern)
            set_filter(pattern)
            return {}
        end
    }, function(reply)
        if not reply or reply == "" then
            require("oil").set_is_hidden_file(default_is_hidden)
        else
            set_filter(reply)
            cur_filter_pattern = reply
        end
    end)
end

---@param command string
local function git_command(command)
    local dir = require("oil").get_current_dir(0)
    if not dir then
        utils.warn("Oil", "Cannot run git command on non-local fs")
        return
    end

    local files = vim.tbl_map(function(e)
        return vim.fn.fnameescape(dir .. "/" .. e.name)
    end, get_entries())

    vim.cmd {
        cmd = "Git",
        mods = {
            silent = true,
        },
        args = { command .. " " .. table.concat(files, " ") }
    }
end
-- }}}

-- Options {{{
local is_git_tracked = function(path)
    return vim.system(
        { "git", "ls-files", "--error-unmatch", path },
        { stdout = false, stderr = false }
    ):wait().code == 0
end

---@type oil.setupOpts
M.opts = {
    buf_options = {
        buflisted = true
    },
    columns = vim.tbl_map(function(c)
        return oil_columns[c] or c
    end, vim.tbl_values(enabled_columns)),
    skip_confirm_for_simple_edits = true,

    git = {
        -- TODO: Evaluate whether I also want something similar for add and remove
        mv = function(src_path, dest_path)
            local should_git_mv = is_git_tracked(src_path) and is_git_tracked(vim.fs.dirname(dest_path))
            -- Synchronise with my git plugin
            if should_git_mv then
                vim.api.nvim_create_autocmd("User", {
                    pattern = "OilMutationComplete",
                    once = true,
                    callback = function(ev)
                        require("config.plugins.oil-git").reload(ev.buf)
                    end
                })
            end

            return should_git_mv
        end,
    },

    float = {
        padding = 8,
        max_width = 80,
        max_height = 40,
    },

    cleanup_delay_ms = 5000,
    extra_scp_args = { "-O" }, -- use scp instead of sftp
    use_default_keymaps = false,
    watch_for_changes = true,

    view_options = {
        -- always show .. to go up so gg<cr> works
        is_hidden_file = default_is_hidden,

        is_always_hidden = function(name, bufnr)
            return name == "." or name == ".."
        end,
        natural_order = true,
        sort = sort,
        highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
            return utils.highlight_fname(nil, entry, is_hidden)
        end
    },
}

M.opts.keymaps = {
    ["!"]              = function() open_cmd("!") end,
    ["<CR>"]           = "actions.select",
    ["<S-CR>"]         = "actions.select_split",
    ["<C-CR>"]         = "actions.select_vsplit",

    -- goto repository
    ["gr"]             = { goto_git_ancestor, mode = "n" },

    -- toggle hidden
    ["gh"]             = "actions.toggle_hidden",

    ["=s"]             = function() set_sort("size") end,
    ["=t"]             = function() set_sort("time") end,
    ["=i"]             = function() set_sort("invert") end,
    ["=d"]             = function() set_sort("default") end,

    ["<localleader>/"] = filter_items,
    ["<localleader>p"] = "actions.preview",
    ["<localleader>:"] = function() open_cmd("") end,
    ["<localleader>g"] = function() toggle_column("group") end,
    ["<localleader>m"] = function() toggle_column("permissions") end,
    ["<localleader>s"] = function() toggle_column("size") end,
    ["<localleader>t"] = function() toggle_column("time") end,
    ["<localleader>b"] = function() toggle_column("birthtime") end,
    ["<localleader>u"] = function() toggle_column("user") end,
    ["<localleader>q"] = {
        "actions.send_to_qflist",
        opts = {
            target = "qflist",
            only_matching_search = true
        }
    },
    ["<localleader>l"] = {
        "actions.send_to_qflist",
        opts = {
            target = "loclist",
            only_matching_search = true
        }
    },
    ["<localleader>o"] = "actions.select_split",
    ["<localleader>v"] = "actions.select_vsplit",
    ["<localleader>x"] = "actions.open_external",

    -- mirror the commands in lua/plugins/git.lua
    ["<space>gs"]      = function() git_command("add") end,
    ["<space>gu"]      = function() git_command("reset --") end,
}
-- }}}

M.config = function(_, opts)
    local map = utils.map
    local oil = require("oil")
    oil.setup(opts)

    local my_columns = require("config.plugins.oil-columns")
    local columns = require("oil.columns")
    columns.register("user", my_columns.user)
    columns.register("group", my_columns.group)
    columns.register("smart_mtime", my_columns.smart_mtime)
    columns.register("smart_btime", my_columns.smart_btime)


    local git_status = require("config.plugins.oil-git")
    -- change directory if not ssh, only for current window
    -- only attach git status for remote as well
    utils.user_autogroup("config.oil", {
        OilEnter = function(ev)
            local dir = oil.get_current_dir()
            if dir then
                vim.fn.chdir(dir)
                git_status.attach(ev.buf)
            end
        end
    })

    -- [p]arent, why use <C-p> if k exists
    map("n", "<C-p>", oil.open)

    map("n", "'e", function()
        vim.cmd("split")
        oil.open()
    end, { desc = "Buffer: Oil" })
    map("n", "'E", function()
        vim.cmd("vsplit")
        oil.open()
    end, { desc = "Buffer: Vertical Oil" })
    map("n", "'<C-e>", function()
        oil.open_float()
    end, { desc = "Buffer: Floating Oil" })
end

return M
