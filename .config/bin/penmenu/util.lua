local M = {}

---@generic K, V
---@param tbl table<K, V>
---@return table<K, V>
M.Enum = function(tbl)
    local rev = {}
    for k, v in pairs(tbl) do
        rev[v] = k
    end

    return setmetatable(tbl, {
        __call = function(self, prm)
            return rev[prm]
        end
    })
end

return M
