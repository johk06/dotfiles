local builtin_picker_maps = {
    ["custom.jumplist"] = "<space>j",
    buffers = "<space><space>",
    command_history = "<space>:",
    diagnostics = "<space>D",
    find_files = "<space>F",
    grep_string = "<space>*",
    help_tags = "<space>h",
    live_grep = "<space>/",
    lsp_document_symbols = "<space>s",
    lsp_workspace_symbols = "<space>S",
    man_pages = "<space>H",
    oldfiles = "<space>o",
    registers = "\"<space>",
    search_history = "<space>?",

    -- git ones, under the same prefix as the fugitive & gitsigns mappings
    git_files = "<space>gf",
    git_status = "<space>gi", -- <space>gs is taken for stage already
    git_commits = "<space>g/",
    git_bcommits = "<space>g?",
}

---@type LazySpec
local M = {
    "nvim-telescope/telescope.nvim",
    keys = vim.tbl_values(builtin_picker_maps),
    cmd = { "Telescope" },
    dependencies = {
        {
            "natecraddock/telescope-zf-native.nvim"
        },
        {
            "nvim-telescope/telescope-ui-select.nvim"
        },
        {
            "nvim-orgmode/telescope-orgmode.nvim"
        }
    },
}

-- HACK: lazy load the ui select provider
M.init = function()
    --- vim.ui.select is meant to be overridden
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.select = function(...)
        require("telescope")
        return vim.ui.select(...)
    end
end

-- defer loading my custom extensions until they're really needed
-- this is necessary so that my mappings etc apply
local custom = function(func)
    return function(...)
        return require("config.plugins.telescope")[func](...)
    end
end

local default_config_tbl = {
    disable_devicons = true,
}

local function default_config(extra)
    return vim.tbl_deep_extend("force", default_config_tbl, extra or {})
end
local lsp_config = default_config {
    jump_type = "drop",
    reuse_win = true,
    layout_config = {
        preview_width = 0.6,
    },
    entry_maker = custom "quickfix_entries"
}
local qfconfig = default_config {
    entry_maker = custom "quickfix_entries"
}

local git_commit = default_config {
    mappings = {
        i = {
            ["<cr>"] = custom "fugitive_commit"
        },
        n = {
            ["<cr>"] = custom "fugitive_commit"
        }
    }
}

-- Configuration {{{
local opts = {}
opts.defaults = {
    create_layout = custom "bottom_pane_layout",
    path_display = custom "path_display",
    default_mappings = {
        n = {
            ["<cr>"]  = custom "select_all_or_one",
            ["t"]     = "select_tab",
            ["e"]     = "file_edit",
            ["s"]     = "select_horizontal",
            ["v"]     = "select_vertical",
            ["<tab>"] = "toggle_selection",

            ["j"]     = "move_selection_next",
            ["k"]     = "move_selection_previous",

            ["gg"]    = "move_to_top",
            ["G"]     = "move_to_bottom",

            ["L"]     = "move_to_bottom",
            ["M"]     = "move_to_middle",
            ["H"]     = "move_to_top",

            ["$"]     = "smart_send_to_qflist",
            ["#"]     = "smart_send_to_loclist",

            ["<esc>"] = "close",
            ["q"]     = "close",
        },
        i = {
            ["<tab>"]  = "toggle_selection",

            ["<cr>"]   = "select_default",
            ["<C-cr>"] = "select_vertical",
            ["<S-cr>"] = "select_horizontal",
            ["<M-j>"]  = "move_selection_next",
            ["<M-k>"]  = "move_selection_previous",
            ["<Down>"] = "move_selection_next",
            ["<Up>"]   = "move_selection_previous",
            ["<C-t>"]  = "select_tab",
            ["<C-e>"]  = "file_edit",
            ["<C-s>"]  = "select_horizontal",
            ["<C-v>"]  = "select_vertical",
        }
    },
    dynamic_preview_title = true,
    results_title = false,
    selection_caret = " ",
    entry_prefix = " ",
    multi_icon = "+",
    prompt_prefix = ":e ",
}

opts.pickers = {
    lsp_definitions = lsp_config,
    lsp_references = lsp_config,
    loclist = qfconfig,
    quickfix = qfconfig,
    lsp_workspace_symbols = default_config {
        entry_maker = custom "lsp_symbol_entries",
    },
    lsp_document_symbols = default_config {
        entry_maker = custom "lsp_symbol_entries",
    },
    diagnostics = default_config {
        entry_maker = custom "diagnostics_entries",
    },
    live_grep = default_config {
        entry_maker = custom "line_and_column_entries",
    },
    grep_string = default_config {
        word_match = "-w",
        entry_maker = custom "line_and_column_entries",
    },
    oldfiles = default_config {
        entry_maker = custom "file_entries",
    },
    buffers = default_config {
        entry_maker = custom "buffer_entries",
        create_layout = custom "bottom_pane_layout",
        sort_lastused = true, -- so i can just <space><space><cr> to cycle
        mappings = {
            n = {
                ["dd"] = "delete_buffer",
            },
        },
        layout_config = {
            height = function()
                local ln = vim.o.lines
                return math.floor(math.min(math.max(ln * 0.2, 12), 32))
            end,
            width = function()
                local col = vim.o.columns
                return math.floor(math.min(math.max(col * 0.3, 48), 60))
            end
        }
    },
    registers = default_config {
        entry_maker = custom "register_entries",
        create_layout = custom "short_layout",
        prompt_prefix = "\" ",
        layout_config = {
            height = function()
                return math.min(vim.o.lines - 4, 32)
            end,
        },
        mappings = {
            n = {
                ["<C-e>"] = custom "edit_register",
                ["<S-cr>"] = "select_default",
                ["<cr>"] = custom "select_register",
                ["\""] = custom "select_register",
                ["p"] = "select_default",
            },
            i = {
                ["<C-e>"] = custom "edit_register",
                ["<S-cr>"] = custom "select_register",
                ["<cr>"] = custom "select_register",
            },
        }
    },
    find_files = default_config {
        entry_maker = custom "file_entries",
    },
    help_tags = default_config {
        prompt_prefix = ":h ",
        -- create_layout = custom "short_layout",
        -- previewer = false,
    },
    man_pages = default_config {
        prompt_prefix = ":man ",
        sections = { "ALL" },
    },
    command_history = default_config {
        create_layout = custom "short_layout",
        prompt_prefix = ": ",
    },
    search_history = default_config {
        create_layout = custom "short_layout",
        prompt_prefix = "/ ",
    },
    treesitter = default_config {
        entry_maker = custom "treesitter_entries",
    },
    git_files = default_config {
        entry_maker = custom "file_entries",
    },
    git_status = default_config {
        -- I don't like this deviating from the convention used everywhere else
        git_icons = {
            added = "A",
            changed = "M",
            copied = "C",
            deleted = "D",
            renamed = "R",
            unmerged = "U",
            untracked = "?",
        }
    },
    git_commits = git_commit,
    git_bcommits = git_commit,
}

opts.extensions = {
    ["zf-native"] = {},
    ["ui-select"] = {
        create_layout = custom "short_layout",
        prompt_prefix = ":",
        layout_config = {
            height = 4,
        }
    },
}
-- }}}

-- Setup {{{
M.config = function()
    local utils = require("config.utils")
    local telescope = require("telescope")

    telescope.setup(opts)
    telescope.load_extension("zf-native")
    telescope.load_extension("ui-select")
    telescope.load_extension("orgmode")

    local builtin = require("telescope.builtin")
    local map = utils.map
    for picker, keys in pairs(builtin_picker_maps) do
        if vim.startswith(picker, "custom.") then
            map("n", keys, custom(picker:sub(#"custom." + 1)))
        else
            map("n", keys, builtin[picker])
        end
    end
end
-- }}}

return M
