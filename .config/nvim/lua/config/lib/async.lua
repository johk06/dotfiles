local M = {}

---@generic T, R
---@param proc fun(arg: T, cb: fun(T): R)
---@param data T[]
---@param cb fun(arg: R[])
M.collect_multiple = function(data, proc, cb)
    local res = {}

    local on_done = function(val)
        table.insert(res, val)
        if #res == #data then
            return cb(res)
        end
    end

    for _, elem in ipairs(data) do
        proc(elem, on_done)
    end
end

return M
