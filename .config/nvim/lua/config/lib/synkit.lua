local M = {}

--[[ Description {{{
Synkit (syn-kit or sync-it) is a way to write classic vim syntax files in lua
by simply specifying the syntax as a set of strings and tables.

TODO: Grouping
}}} ]]

-- Types {{{
---@alias synkit.DetailedMatch {[1]: string, conceal: string?, spell: boolean?, contained: boolean, containedin: string[]}
---@alias synkit.Match (string|synkit.DetailedMatch)
---@alias synkit.Keyword string|{[integer]: string, conceal: string?}
---@alias synkit.Region {start: string, stop: string, skip: string?, contains: string[]?}

---@alias synkit.MatchEntry {[integer]: synkit.Match, priority: integer?}

---@alias synkit.Matches table<string, synkit.MatchEntry>
---@alias synkit.Keywords table<string, synkit.Keyword[]>
---@alias synkit.Regions table<string, synkit.Region>


---@class synkit.Syntax
---@field name string
---@field iskeyword string?
---@field keywords synkit.Keywords
---@field match synkit.Matches
---@field regions synkit.Regions

-- }}}

local title = function(s)
    return s:sub(1, 1):upper() .. s:sub(2)
end

local tosyngroup = function(g)
    return table.concat(vim.tbl_map(title, vim.split(g, "%.")))
end

local created_groups = {}

---@param syn string
---@param group string
local mkname = function(syn, group)
    local g = syn .. tosyngroup(group)
    if not created_groups[g] then
        vim.api.nvim_set_hl(0, g, { link = ("@%s.%s"):format(group, syn) })
        created_groups[g] = true
    end
    return g
end
local mklist = function(name, list)
    return table.concat(vim.tbl_map(function(c)
        return mkname(name, c)
    end, list), ",")
end

---@param syn synkit.Syntax
---@param pattern synkit.DetailedMatch
local mksuffix = function(syn, pattern)
    local suffix = {}
    if pattern.spell then
        table.insert(suffix, "contains=@Spell")
    end
    if pattern.conceal then
        table.insert(suffix, "conceal cchar=" .. pattern.conceal)
    end
    if pattern.contained then
        table.insert(suffix, "contained")
    end
    if pattern.containedin then
        table.insert(suffix, "containedin=" .. mklist(syn.name, pattern.containedin))
    end

    return table.concat(suffix, " ")
end

---@param group string
---@param spec string
local match = function(group, spec, suffix)
    vim.cmd.syntax(("match %s '%s' %s"):format(group, spec:gsub("'", "\\'"), suffix))
end

local keyword = function(group, word, suffix)
    vim.cmd.syntax(("keyword %s %s %s"):format(group, word, suffix))
end

---@return string[]
local expand_string_pattern = function(patterns)
    return vim.tbl_filter(function(ptrn)
        return #ptrn > 0
    end, vim.tbl_map(vim.trim, vim.split(patterns, "%s")))
end

---@param list synkit.Keyword[]
---@param group string
local do_keywd_list = function(list, group)
    local items, suffix
    for _, word in ipairs(list) do
        if type(word) == "table" then
            suffix = word.conceal and "conceal cchar=" .. word.conceal or ""
            items = word
        else
            suffix = ""
            items = { word }
        end

        for _, w in ipairs(items) do
            keyword(group, w, suffix)
        end
    end
end

---@param syn synkit.Syntax
M.syntax = function(syn)
    if vim.b.current_syntax then
        return
    end
    vim.b.current_syntax = syn.name

    if syn.iskeyword then
        vim.bo.iskeyword = syn.iskeyword
    end

    for group, words in pairs(syn.keywords) do
        if type(group) == "string" then
            do_keywd_list(words, mkname(syn.name, group))
        end
    end

    for reg, region in pairs(syn.regions) do
        local extra = {
            region.skip and "skip=+" .. region.skip .. "+",
        }

        if region.contains then
            local contains = mklist(syn.name, region.contains)
            table.insert(extra, "contains=" .. contains)
        end
        vim.cmd.syntax(("region %s start=+%s+ end=+%s+ %s"):format(
            mkname(syn.name, reg),
            region.start,
            region.stop,
            table.concat(extra, " "))
        )
    end

    local groups = vim.tbl_keys(syn.match)
    table.sort(groups, function(a, b)
        local enta = syn.match[a]
        local entb = syn.match[b]
        local prioa = (type(enta) == "table" and enta.priority) or 0
        local priob = (type(entb) == "table" and entb.priority) or 0

        return prioa < priob
    end)
    for _, group in ipairs(groups) do
        local gname = mkname(syn.name, group)
        local patterns = syn.match[group]

        for _, pattern in ipairs(patterns) do
            local list, suffix
            if type(pattern) == "table" then
                ---@cast pattern string[]
                list = pattern
                suffix = mksuffix(syn, pattern)
            else
                list = expand_string_pattern(pattern)
                suffix = ""
            end

            for _, rx in ipairs(list) do
                match(gname, rx, suffix)
            end
        end
    end
end

return M
