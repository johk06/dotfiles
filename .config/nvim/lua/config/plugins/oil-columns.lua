local M = {}

--[[
Allow showing file user and group in oil
TODO: Allow editing via Column.perform_action
- This may not be necessary as this is usually limited to root anyways
- NOTE: this may make more sense for the groups column
]]

local constants  = require("oil.constants")
local utils      = require("config.utils")
local FIELD_META = constants.FIELD_META
local uv         = vim.uv

---@type {[integer]: string}
local Users
---@type {[integer]: string}
local Groups
do
    local read_passwd_file = function(path)
        ---@type {[integer]: string}
        local out = {}
        local file = assert(io.open(path))
        local entries = vim.split(file:read("*a"), "\n")
        for _, entry in ipairs(entries) do
            local fields = vim.split(entry, ":")
            local id = tonumber(fields[3])
            if not id then
                goto continue
            end
            out[id] = fields[1]
            ::continue::
        end
        file:close()

        return out
    end

    Users = read_passwd_file("/etc/passwd")
    Groups = read_passwd_file("/etc/group")
end


---@param line string
local parse_owner = function(line)
    local group, rest = line:match("^(%S+)%s+(.*)$")

    return group, rest
end

---@return oil.ColumnDefinition
---@param statfield "uid"|"gid"
---@param fallback "user"|"group"
---@param highlight string
---@param name_lookup table<integer, string>
local make_entry = function(statfield, fallback, highlight, name_lookup)
    ---@type oil.ColumnDefinition
    return {
        parse = parse_owner,
        render = function(entry)
            if not entry[FIELD_META] then
                return ""
            end
            local value
            local st = entry[FIELD_META]

            if st.stat then
                ---@cast st {stat: uv.fs_stat.result}
                value = name_lookup[st.stat[statfield]] or tostring(st.stat[statfield])
            else
                value = st[fallback] or ""
            end

            return { value, highlight }
        end,
    }
end

M.user = make_entry("uid", "user", "OilUser", Users)
M.group = make_entry("gid", "group", "OilGroup", Groups)

---@return oil.ColumnDefinition
local make_smart_time = function(field)
    return {
        render = function(entry)
            local meta = entry[FIELD_META]
            if not meta then
                return nil
            end

            ---@type integer
            local time = meta.stat and meta.stat[field].sec
            if not time then
                return nil
            end

            return utils.format_time_smart(time)
        end,
        parse = function(line)
            -- NOTE: all formats consist of two WORDs
            return line:match("^(%S+%s+%S+)%s+(.+)$")
        end,
        get_sort_value = function(entry)
            local meta = entry[FIELD_META]
            local stat = meta and meta.stat
            if stat and stat[field] then
                return stat[field].sec
            else
                return 0
            end
        end
    }
end

M.smart_mtime = make_smart_time("mtime")
M.smart_btime = make_smart_time("birthtime")

return M
