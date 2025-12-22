local M = {}

--[[ Description {{{
Synkit (syn-kit or sync-it) is a way to write classic vim syntax files in lua
by simply specifying the syntax as a set of strings and tables.

TODO: Grouping
}}} ]]

-- Types {{{
---@alias synkit.DetailedMatch {[1]: string, conceal: string?, spell: boolean?}
---@alias synkit.Match (string|synkit.DetailedMatch)
---@alias synkit.Keyword string|{[integer]: string, conceal: string?}

---@alias synkit.MatchEntry {[integer]: synkit.Match, priority: integer?}

---@alias synkit.Matches table<string, synkit.MatchEntry>
---@alias synkit.Keywords table<string, synkit.Keyword[]>

---@class synkit.Syntax
---@field name string
---@field iskeyword string?
---@field keywords synkit.Keywords
---@field match synkit.Matches
-- }}}

---@param syn string
---@param group string
local mkname = function(syn, group)
    return ("@%s.%s"):format(group, syn)
end

---@param pattern synkit.DetailedMatch
local mksuffix = function(pattern)
    local suffix = {}
    if pattern.spell then
        table.insert(suffix, "contains=@Spell")
    end
    if pattern.conceal then
        table.insert(suffix, "conceal cchar=" .. pattern.conceal)
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
                suffix = mksuffix(pattern)
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
