--[[ Really simple snippet expansion system
 - A snippet can be a table or a string
 - Loads snippets from lua files on the runtimepath
    - This makes snippets easier to reason about
    - NOTE: to clear the cache: `:lua require("config.lib.blink.snippets").filetype_cache.lua = nil`
 - Uses native vim.snippet to expand etc -> works the same as LSP
 - Supports blink

 Credits:
 - https://nvim-mini.org/mini.nvim/readmes/mini-snippets
    - Doesn't use vim.snippet -> Mappings don't work, different look & feel
    - Using the runtimepath is a great idea, but I don't need json support, lua feels much nicer
    - Generally a bit more complex than what I need
 ]]

---@class blink.cmp.JhkSnippetSource : blink.cmp.Source
---@field filetype_cache table<string, table<string, string>|false>

local api = vim.api
local utils = require("config.utils")

---@alias config.snippet string|table
---@alias config.snippet_map table<string, config.snippet>

---@class blink.cmp.JhkSnippetSource
local Source = {
    filetype_cache = {}
}

---@param ft string
local load_per_filetype = function(ft)
    local per_ft = Source.filetype_cache[ft]
    if per_ft == nil then
        local file = api.nvim_get_runtime_file(("snippet/%s.lua"):format(ft), false)[1]
        if not file then
            Source.filetype_cache[ft] = false
            return
        end

        local ok, values_or_err = pcall(dofile, file)
        if not ok then
            utils.error("Snippet", ("Failed to load snippets for %s: %s"):format(ft, values_or_err))
            Source.filetype_cache[ft] = false
            return
        end

        ---@cast values_or_err config.snippet_map
        if type(values_or_err) ~= "table" then
            utils.error("Snippet", ("Failed to load snippets for %s: Not a table"):format(ft))
            Source.filetype_cache[ft] = false
            return
        end


        local res = {}
        for k, v in pairs(values_or_err) do
            res[k] = type(v) == "table" and table.concat(v, "\n") or v
        end

        Source.filetype_cache[ft] = res

        return res
    elseif per_ft then
        return per_ft
    end
end

---@param snippets table<string, string>
local to_comp_items = function(snippets)
    local res = {}

    for k, val in vim.spairs(snippets) do
        ---@type lsp.CompletionItem
        local item = {
            kind = require("blink.cmp.types").CompletionItemKind.Snippet,
            label = k,
            insertText = val,
            insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
        }
        table.insert(res, item)
    end

    return res
end

Source.new = function(opts, config)
    return setmetatable({}, {
        __index = Source
    })
end

function Source:enabled()
    return true
end

function Source:get_completions(ctx, cb)
    local items = load_per_filetype(vim.bo.ft)
    if not items then
        return
    end

    local comp_items = to_comp_items(items)
    cb {
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = comp_items,
    }
end

function Source:resolve(item, cb)
    local parsed = require("blink.cmp.sources.snippets.utils").safe_parse(item.insertText)
    local snippet = parsed and tostring(parsed) or item.insertText

    local resolved = vim.deepcopy(item)
    resolved.detail = snippet
    cb(item)
end

return Source
