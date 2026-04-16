---@type zpack.Spec
local M = {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    build = Jhk.pack_build_cmd {"cargo", "build", "--release"},
    dependencies = {},
}

---@type blink.cmp.Config
local opts = {}
M.opts = opts

opts.keymap = {
    preset    = "none",
    ["<C-e>"] = { "cancel", "fallback" },              -- [e]xit
    ["<C-j>"] = { "show", "select_next", "fallback" }, -- really nice and quick directly under my index finger
    ["<C-l>"] = { "accept", "show", "fallback" },      -- mirror command line
    ["<C-n>"] = { "show", "select_next", "fallback" }, -- [n]ext
    ["<C-p>"] = { "show", "select_prev", "fallback" }, -- [p]revious
}

opts.signature = {
    enabled = true,
    trigger = {
        enabled = true
    }
}

opts.cmdline = {
    keymap = {
        -- mapping <left> and <right> is not what I ever want
        preset     = "none",

        ["<Tab>"]  = { "show_and_insert", "select_next" },
        ["<C-j>"]  = { "select_next", "fallback" },
        ["<C-n>"]  = { "select_next", "fallback" },
        ["<C-p>"]  = { "select_prev", "fallback" },
        ["<C-e>"]  = { "cancel" },
        ["<C-y>"]  = { "select_and_accept" },
        ["<S-CR>"] = { "select_accept_and_enter" },
    },
    completion = {
        menu = {
            -- incredibly useful for :find
            auto_show = true,
        }
    }
}

-- quick accept with <M-number>
-- 0 for the first is *intentionally* not that easy to reach, as that is
-- usually the least important candidate
for i = 0, 9 do
    local action = {
        function(cmp)
            cmp.accept { index = i + 1 }
        end
    }
    local key = ("<M-%d>"):format(i)

    opts.keymap[key] = action
    opts.cmdline.keymap[key] = action
end

opts.completion = {
    list = {
        max_items = 20,
    },
    documentation = {
        auto_show = true,
        auto_show_delay_ms = 50,
        window = {
            scrollbar = false,
        }
    },
    menu = {
        scrollbar = false,
        max_height = 24,
        min_width = 30,
        draw = {
            columns = {
                { "index" },
                { "label",    "label_description", gap = 1 },
                { "kind_icon" },
            },
            components = {}
        }
    },
}

opts.completion.menu.draw.components = {
    index = {
        text = function(ctx)
            return ctx.idx > 10 and "" or tostring(ctx.idx - 1)
        end,
        highlight = "BlinkCmpIndex",
    },
    kind_icon = {
        text = function(ctx)
            local utils = require("config.utils")
            if ctx.source_name == "Cmdline" then
                return
            end

            return utils.lsp_symbols[ctx.kind]
        end,
    },
    label = {
        width = {
            max = 30,
            fill = true
        },
    },
    label_description = {
        width = {
            max = 20,
        },
    }
}

-- (Neo)Vim has a nice omnifunc for css: 'ft-css-omni'
local css_sources = { "omni", "lua_snippets", "path", "buffer" }

opts.sources = {
    default = { "lsp", "path", "lua_snippets", "buffer" },
    per_filetype = {
        oil = { "path", "buffer", "lua_snippets" },
        Input = { "omni" },
        css = css_sources,
        scss = css_sources,
    },
    providers = {
        lua_snippets = {
            module = "config.plugins.blink-snippets",
        },
        path = {
            opts = {
                -- more useful tbh
                get_cwd = function()
                    return vim.fn.getcwd()
                end
            }
        }
    }
}

return M
