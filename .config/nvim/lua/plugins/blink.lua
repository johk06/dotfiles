--[[ Rationale {{{
This is a fairly fast and capable completion engine.
While I do not agree with all (or even a majority of) its design choices,
I can simply not use these things.
}}} ]]

---@param ctx blink.cmp.Context
---@param items blink.cmp.CompletionItem[]
local keep_capitalization = function(ctx, items)
    local kwd = ctx.get_keyword()
    local correct, case
    if kwd:match("^%l") then
        correct = "^%u%l+$"
        case = string.lower
    elseif kwd:match("^%u") then
        correct = "^%l+$"
        case = string.upper
    else
        return items
    end

    local seen = {}
    local out = {}
    for _, itm in ipairs(items) do
        local raw = itm.insertText
        if not raw then
            goto continue
        end
        if raw:match(correct) then
            local text = case(raw:sub(1, 1)) .. raw:sub(2)
            itm.insertText = text
            itm.label = text
        end
        if not seen[itm.insertText] then
            seen[itm.insertText] = true
            table.insert(out, itm)
        end

        ::continue::
    end

    return out
end

---@type zpack.Spec
local M = {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    build = function()
        require("blink.cmp").build():wait(60000) -- 1 minute
    end,
    dependencies = {
        "saghen/blink.lib" -- required dependency
    },
}

---@type blink.cmp.Config
local opts = {}
M.opts = opts

opts.keymap = {
    preset    = "none",
    -- exit, escape
    ["<C-e>"] = { "cancel", "fallback" },
    -- really nice and quick directly under my index finger,
    -- TODO: check how much I use digraphs, maybe remap <C-k>?
    ["<C-j>"] = { "show", "select_next", "fallback" },
    -- mirror command line
    ["<C-l>"] = { "accept", "show", "fallback" },
    ["<C-n>"] = { "show", "select_next", "fallback" },
    ["<C-p>"] = { "show", "select_prev", "fallback" },
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
        min_width = 24,
        draw = {
            columns = {
                { "label",    "label_description", gap = 1 },
                { "kind_icon" },
                { "index" },
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
        },
        buffer = {
            -- When completing using a word beginning with a capital letter, keep that
            -- Since the buffer mode is primarily in use in comments &c, this is nice
            transform_items = keep_capitalization
        }
    }
}

return M
