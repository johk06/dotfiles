local M = {}

local api = vim.api
local utils = require("config.utils")
local operators = require("config.lib.operators")

---@type string[]|nil
local last_text = nil
---@type string
local reg = nil

local sh_name_transformer = function(name, value)
    if value[1]:find([=[["\\]]=]) then
        return ('"$%s"'):format(name)
    end
    return ('${%s}'):format(name)
end

local sh_assignment_generator = function(name, value)
    value[1] = ("%s=%s"):format(name, value[1])
    return value
end

---@type table<string, fun(name: string, value: string[]): string[]?>
M.assignment_generators = {
    lua = function(name, value)
        local valstart = vim.trim(value[1])

        -- table assignment does not need or use the local keyword
        if name:find("%.") or name:find("%[") then
            value[1] = ("%s = %s"):format(name, valstart)
            return value
        end

        value[1] = ("local %s = %s"):format(name, valstart)
        return value
    end,
    bash = sh_assignment_generator,
    sh = sh_assignment_generator,
}

---@type table<string, fun(name: string, value: string[]): string>
M.name_transformers = {
    bash = sh_name_transformer,
    sh = sh_name_transformer
}

Jhk.extract_opfunc = function(mode)
    if not last_text then
        return
    end
    local text = last_text

    local ft = vim.bo.ft
    local assigner = M.assignment_generators[ft]
    if not assigner then
        utils.error("Extract", ("No extractor for '%s'"):format(ft))
        return
    end
    local name = vim.fn.input("Name: ")
    local region = operators.get_op_region(mode)
    local lines = operators.get_region("line", region)
    local variable = name
    if M.name_transformers[ft] then
        variable = M.name_transformers[ft](name, text)
    end

    local replacements = {}

    -- only a single line value
    if #text == 1 then
        local pattern = text[1]:gsub("%p", "%%%0")
        local plain_replacement = variable:gsub("%%", "%%%%")
        for i, line in ipairs(lines) do
            table.insert(replacements, (line:gsub(pattern, plain_replacement)))
        end
    else
        local as_text = table.concat(lines, "\n")
        local multiline_regex_builder = {}
        for _, line in ipairs(text) do
            if line:match("^%s+") then
                table.insert(multiline_regex_builder, true)
            end
            table.insert(multiline_regex_builder, vim.trim((line:gsub("\\", "\\\\"))))
            if line:match("%s+$") then
                table.insert(multiline_regex_builder, true)
            end
            table.insert(multiline_regex_builder, true)
        end
        local regex = {}
        for i = 1, #multiline_regex_builder do
            local el = multiline_regex_builder[i]
            if el == true and multiline_regex_builder[i + 1] ~= true then
                table.insert(regex, "\\_s\\+")
            elseif el ~= true then
                table.insert(regex, el)
            end
        end
        regex[#regex] = nil
        local res = vim.fn.substitute(as_text, table.concat(regex), variable, "g")
        replacements = vim.split(res, "\n")
    end

    local assignment = M.assignment_generators[ft](name, text)
    if assignment then
        api.nvim_buf_set_lines(0, region[1][1] - 1, region[2][1], false, replacements)
        vim.fn.setreg(reg, assignment)
    end
end

---@type config.op.operator_func
M.extract_to_variable = function(mode, region, extra)
    reg = vim.v.register
    last_text = operators.get_region(mode, region)
    vim.o.opfunc = "v:lua.Jhk.extract_opfunc"

    local match_text = ("\\M%s"):format(table.concat(last_text, "\n"):gsub("\\", "\\\\"))
    local match_id = vim.fn.matchadd("Visual", match_text, 2)

    api.nvim_feedkeys("g@", "n", false)

    api.nvim_create_autocmd("SafeState", {
        once = true,
        callback = function()
            if match_id then
                vim.fn.matchdelete(match_id, 0)
            end
        end
    })
end

return M
