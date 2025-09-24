local M = {}

local ts = vim.treesitter

---@type table<string, table<string, vim.treesitter.Query>>
local query_cache = setmetatable({}, {
    __index = function(t, k)
        if rawget(t, k) == nil then
            rawset(t, k, {})
        end

        return rawget(t, k)
    end
})

---@param lang string
---@param query string
---@return vim.treesitter.Query?
M.get_query = function(lang, query)
    if not query_cache[lang][query] then
        query_cache[lang][query] = ts.query.get(lang, query)
    end

    return query_cache[lang][query]
end

---@param parents TSNode[]
---@param child TSNode
---@return boolean()
local is_child_of_any_parent = function(parents, child)
    for _, parent in ipairs(parents) do
        if parent:child_with_descendant(child) ~= nil then
            return true
        end
    end

    return false
end

---@param buf integer
---@param query_group string
---@param capture string
---@param range Range4
---@param recursive boolean
---@return TSNode[]?
M.get_matches_in_range = function(buf, query_group, capture, range, recursive)
    buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
    local lang = ts.language.get_lang(vim.bo[buf].ft)
    if not lang then
        return nil
    end

    local query = M.get_query(lang, query_group)
    if not query then
        return nil
    end

    local parser = ts.get_parser(buf, lang)
    if not parser then
        return nil
    end

    local tree = parser:trees()[1]
    if not tree then
        return nil
    end

    local nodes = {}
    local seen = {}
    for id, node, meta in query:iter_captures(tree:root(), buf) do
        local name = query.captures[id]
        local srow, scol, erow, ecol = ts.get_node_range(node)

        if name == capture
            and ts._range.contains(range, { srow, scol, erow, ecol })
            and (recursive or not is_child_of_any_parent(seen, node)) then
            table.insert(nodes, node)
            table.insert(seen, node)
        end
    end

    return nodes
end

return M
