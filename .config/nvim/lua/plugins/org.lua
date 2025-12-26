---@type LazySpec
local M = {
    "nvim-orgmode/orgmode",
    cmd = { "Org" },
    ft = { "org" },
    keys = { "<space>A" },
    init = function()
        -- HACK: forward requests to the global Org object until it is loaded
        _G.Org = setmetatable({}, {
            __index = function(_, k)
                require("orgmode")
                return Org[k]
            end
        })
    end,
    dependencies = {
        {
            "johk06/orgmode-eval",
            opts = {},
        },
        {
            "nvim-orgmode/telescope-orgmode.nvim"
        }
    }
}

---@type OrgConfigOpts
local opts = {
    hyperlinks = {
        sources = {
        }
    },
    ui = {
        input = {
            use_vim_ui = true,
        },
        folds = {
            colored = true
        },
    },
    org_agenda_files = {
        "~/org/**/*",
        "~/uni/**/*",
        "~/doc/*"
    },
    org_default_notes_file = "~/org/notes.org",
    org_todo_keywords = {
        "TODO(t)", "NEXT(n)", "WAITING(w)", "CURRENT(c)",
        "|",
        "DONE(d)", "NOPE(x)",
    },
    org_todo_keyword_faces = {
        -- HACK: see https://github.com/nvim-orgmode/orgmode/issues/983
        NEXT = ":foreground red",
        WAITING = ":foreground red",
        CURRENT = ":foreground red",
        NOPE = ":foreground red",
    },
    org_startup_folded = "inherit",
    org_hide_leading_stars = true,
    org_hide_emphasis_markers = true,
    org_startup_indented = true,
    org_tags_column = 0,
}

opts.org_agenda_custom_commands = {
    u = {
        description = "Uni",
        types = {
            {
                type = "agenda",
                match = "uni",
                org_agenda_span = "month"
            }
        }
    }
}

opts.org_capture_templates = {}

--- Mappings {{{
opts.mappings = {
    global = {
        org_agenda = "<space>A",
    },
}
opts.mappings.agenda = {
    org_agenda_day_view           = "<localleader>d",
    org_agenda_month_view         = "<localleader>m",
    org_agenda_week_view          = "<localleader>w",
    org_agenda_year_view          = "<localleader>y",
    org_agenda_filter             = "<localleader>/",

    -- I like my find motions, so keep [nN]
    org_agenda_later              = ">",
    org_agenda_earlier            = "<",
    org_agenda_today              = ".",
    org_agenda_goto_date          = "?",

    org_agenda_add_note           = "o",
    org_agenda_deadline           = "d",
    org_agenda_schedule           = "s",
    org_agenda_archive            = "A",

    ---@diagnostic disable: assign-type-mismatch Type annotations do not match the docs
    org_agenda_set_effort         = false,
    org_agenda_clock_goto         = false,
    org_agenda_refile             = false,
    org_agenda_set_tags           = false,
    org_agenda_toggle_archive_tag = false,
    ---@diagnostic enable
}
opts.mappings.capture = {
    org_capture_kill = "<localleader>q",


    ---@diagnostic disable-next-line: assign-type-mismatch
    org_capture_refile = false,
}
opts.mappings.note = {
    org_note_kill = "<localleader>q",
}
opts.mappings.org = {
    org_toggle_heading                      = "<localleader>*",
    org_store_link                          = "<localleader>y",
    org_insert_link                         = "<localleader>p",
    org_edit_special                        = "<localleader>e",
    org_add_note                            = "<localleader>n",
    org_archive_subtree                     = "<localleader>A",
    org_toggle_archive_tag                  = "<localleader>a",
    org_meta_return                         = "<localleader>o",
    org_insert_heading_respect_content      = "<localleader>h",
    org_insert_todo_heading_respect_content = "<localleader>d",

    org_move_subtree_up                     = "<t",
    org_move_subtree_down                   = ">t",
    org_timestamp_down_day                  = "<d",
    org_timestamp_up_day                    = ">d",


    org_priority              = "cp",
    org_schedule              = "c@",
    org_deadline              = "c!",
    org_time_stamp            = "y.",
    org_time_stamp_inactive   = "g.",
    org_set_tags_command      = "c:",

    org_clock_in              = "<localleader>ci",
    org_clock_out             = "<localleader>cq",
    org_clock_cancel          = "<localleader>cc",
    org_clock_goto            = "<localleader>cg",

    org_export                = "<localleader>x",
    org_babel_tangle          = "<localleader>X",
    org_refile                = "<localleader>r",

    org_open_at_point         = "<cr>",

    ---@diagnostic disable: assign-type-mismatch
    org_insert_todo_heading   = false,
    org_set_effort            = false,
    -- I prefer my own tab
    org_cycle                 = false,
    org_toggle_timestamp_type = false,
    ---@diagnostic enable
}
-- }}}

-- Custom Directives {{{
---@type table<string, fun(file: OrgFile, value: string|string[])>
local custom_opts = {
    language = function(file, value)
        if type(value) == "string" then
            if value:match("%s*%-%s*") then
                vim.bo[file.buf].spelllang = ""
            else
                vim.bo[file.buf].spelllang = value:gsub("%s*,", ",")
            end
        else
            vim.bo[file.buf].spelllang = table.concat(value, ",")
        end
    end,
    width = function(file, value)
        if type(value) == "string" then
            vim.bo[file.buf].textwidth = tonumber(value) or 0
        end
    end
}

---@param file OrgFile
local handle_custom_opts = function(file)
    for name, cb in pairs(custom_opts) do
        local val = file:get_directive(name)
        if val then
            cb(file, val)
        end
    end
end
-- }}}

M.config = function()
    local utils = require("config.utils")
    local custom = require("config.plugins.orgmode")
    local eval = require("orgmode-eval")
    require("telescope").load_extension("orgmode")

    opts.ui.menu = { handler = custom.menu }
    opts.org_custom_exports = {
        t = custom.typst_exporter
    }
    local orgmode = require("orgmode")
    orgmode.setup(opts)

    orgmode.links:add_type(custom.line_start_link)
    orgmode.links:add_type(custom.regex_search_link)
    orgmode.links:add_type(custom.manpage_link)

    utils.autogroup("config.orgmode", {
        FileType = {
            pattern = "org",
            callback = function(ev)
                vim.wo.conceallevel = 2
                vim.wo.concealcursor = "nc"
                local map = utils.local_mapper(ev.buf)
                map("n", "<localleader>l", "<cmd>Telescope orgmode insert_link<cr>")
                map("n", "<localleader>/", "<cmd>Telescope orgmode search_headings<cr>")

                -- The default <cr> mapping is nothing but broken
                map("i", "<cr>", "<cr>")

                map("i", "<M-CR>", function()
                    orgmode.action("org_mappings.meta_return")
                end)

                map("n", "<space>e", eval.run_code_block)
                map("n", "<space>E", eval.clear_buffer)

                -- Mimic markdown
                map("n", "gO", custom.table_of_contents)

                handle_custom_opts(orgmode.files:get(vim.api.nvim_buf_get_name(ev.buf)))
            end
        },
    })
end

return M
