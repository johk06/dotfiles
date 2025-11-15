--[[ Really simple snippet expansion syste
 - A snippet can be a table or a string or a function that returns either of those
 - Loads snippets from lua files on the runtimepath
    - This makes snippets easier to reason about
    - NOTE: to clear the cache: `:lua require("config.snippets").filetype_cache.lua = nil`
 - Uses native vim.snippet to expand etc -> works the same as LSP 

 Credits:
 - https://nvim-mini.org/mini.nvim/readmes/mini-snippets
    - Doesn't use vim.snippet -> Mappings don't work, different look & feel
    - Using the runtimepath is a great idea, but I don't need json support, lua feels much nicer
    - Generally a bit more complex than what I need (e.g. completion engine support)
 ]]

local api = vim.api
local utils = require("config.utils")

local M = {}

---@alias config.snippet string|table|fun(): string|table
---@alias config.snippet_map table<string, config.snippet>

---@type table<string, config.snippet_map|false>
M.filetype_cache = {}

---@param ft string
local load_per_filetype = function(ft)
    local per_ft = M.filetype_cache[ft]
    if per_ft == nil then
        local file = api.nvim_get_runtime_file(("snippet/%s.lua"):format(ft), false)[1]
        if not file then
            M.filetype_cache[ft] = false
            return
        end

        local ok, values_or_err = pcall(dofile, file)
        if not ok then
            utils.error("Snippet", ("Failed to load snippets for %s: %s"):format(ft, values_or_err))
            M.filetype_cache[ft] = false
            return
        end

        if type(values_or_err) ~= "table" then
            utils.error("Snippet", ("Failed to load snippets for %s: Not a table"):format(ft))
            M.filetype_cache[ft] = false
            return
        end

        M.filetype_cache[ft] = values_or_err

        return values_or_err
    elseif per_ft then
        return per_ft
    end
end

---@param snippets config.snippet_map
---@param text string
---@return config.snippet?
---@return [integer, integer]? Region to replace
local get_best_match = function(snippets, text)
    local wordstart, wordstop, actual_word = text:find("(%w+)$")
    if not actual_word then
        return
    end
    local best_count, best_snip = 0, nil

    for prefix, snip in pairs(snippets) do
        local start, stop = prefix:find(actual_word, 1, true)
        if start == 1 and stop and stop > best_count then
            best_count = stop
            best_snip = snip
        end
    end

    return best_snip, { wordstart - 1, wordstop }
end

---@param snippet config.snippet
local do_expansion = function(snippet)
    local final_snip
    if type(snippet) == "function" then
        snippet = snippet()
    end

    if type(snippet) == "table" then
        final_snip = table.concat(snippet, "\n")
    else
        final_snip = snippet
    end

    vim.snippet.expand(final_snip)
end

M.expand = function()
    local snippets = load_per_filetype(vim.bo.ft)
    if not snippets then
        return
    end

    local cursor = api.nvim_win_get_cursor(0)
    local line_before_cursor = api.nvim_get_current_line():sub(1, cursor[2])
    local best_match, range = get_best_match(snippets, line_before_cursor)
    if not best_match or not range then
        return
    end

    api.nvim_buf_set_text(0, cursor[1] - 1, range[1], cursor[1] - 1, range[2], {})
    do_expansion(best_match)
end

return M
