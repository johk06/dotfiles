local utils = require("config.utils")

---@alias config.snippet.expr string|string[]|fun(): string|string[]

---@class config.Snippet
---@field desc string Description
---@field expand config.snippet.expr Value

---@alias config.SnippetConfig table<string, config.Snippet>

---@type table<string, config.SnippetConfig|false>
local cache = {}

---@return config.SnippetConfig?
local load_snippets_for = function(ft)
    local luafile = vim.api.nvim_get_runtime_file(("snippet/%s.lua"):format(ft), false)[1]
    if not luafile then
        cache[ft] = false
        return
    end
    local ok, spec_or_err = pcall(dofile, luafile)
    if not ok then
        utils.error("Snippets", ("Failed to load: %s"):format(spec_or_err))
        cache[ft] = false
        return
    end

    ---@cast spec_or_err config.SnippetConfig
    cache[ft] = spec_or_err
    return spec_or_err
end

---@param buf integer
---@return config.SnippetConfig?
---@return string
local get_buf_snippets = function(buf)
    local ft = vim.bo[buf].filetype
    return cache[ft] == false and nil or cache[ft] or load_snippets_for(ft), ft
end

---@class (exact) config.snippet.BlinkSource : blink.cmp.Source
local S = {}
S.new = function()
    return setmetatable({}, { __index = S })
end

S.enabled = function(self)
    return not not get_buf_snippets(0)
end

S.get_completions = function(self, ctx, cb)
    local snips, ft = get_buf_snippets(ctx.bufnr)
    if not snips then
        ---@diagnostic disable-next-line: missing-return-value
        return
    end

    ---@type lsp.CompletionItem[]
    local items = {}
    for name, snippet in pairs(snips) do
        ---@type lsp.CompletionItem
        local item = {
            kind = 15, -- Snippet
            label = name,
            description = snippet.desc,
            insertText = name,
            data = { snippet = snippet }
        }
        table.insert(items, item)
    end

    cb {
        is_incomplete_backward = false,
        is_incomplete_forward = false,
        items = items,
        ---@diagnostic disable-next-line: missing-return
    }
end

S.resolve = function(self, item, cb)
    ---@type config.Snippet
    local snip = item.data.snippet

    local resolved = vim.deepcopy(item)
    resolved.documentation = {
        kind = "markdown",
        snip.desc
    }

    local value = snip.expand
    if type(value) == "function" then
        resolved.detail = "*function*"
    elseif type(value) == "table" then
        resolved.detail = table.concat(value, "\n")
    else
        resolved.detail = value
    end

    cb(resolved)
end

S.execute = function(self, ctx, item)
    local text_edits = require("blink.cmp.lib.text_edits")
    text_edits.apply {
        newText = "",
        range = text_edits.get_from_item(item).range
    }

    ---@type config.Snippet
    local snippet = item.data.snippet

    local value = snippet.expand
    if type(snippet.expand) == "function" then
        value = snippet.expand()
    end

    if type(value) == "table" then
        value = table.concat(value, "\n")
    end

    vim.snippet.expand(value)
end

return S
